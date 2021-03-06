/*****************************************************************************
 **
 ** FinalBurn X: Port of FinalBurn to OS X
 ** https://github.com/0xe1f/FinalBurn-X
 ** Copyright (C) Akop Karapetyan
 **
 ** Licensed under the Apache License, Version 2.0 (the "License");
 ** you may not use this file except in compliance with the License.
 ** You may obtain a copy of the License at
 **
 **     http://www.apache.org/licenses/LICENSE-2.0
 **
 ** Unless required by applicable law or agreed to in writing, software
 ** distributed under the License is distributed on an "AS IS" BASIS,
 ** WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 ** See the License for the specific language governing permissions and
 ** limitations under the License.
 **
 ******************************************************************************
 */
#import "FXZipArchive.h"

@interface FXZipArchive ()

- (void)invalidateFileCache;
- (BOOL)locateFileWithCRC:(NSUInteger)crc
                    error:(NSError **)error;

@end

@implementation FXZipArchive

- (instancetype)initWithPath:(NSString *)path
                       error:(NSError **)error
{
    if (self = [super init]) {
        const char *cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
        self->zipFile = unzOpen(cpath);
        if (self->zipFile != NULL) {
            [self setPath:path];
        } else {
            if (error != NULL) {
                *error = [NSError errorWithDomain:@"org.akop.fbx.Zip"
                                           code:FXErrorLoadingArchive
                                       userInfo:@{ NSLocalizedDescriptionKey : @"Error loading archive" }];
            }
        }
    }
    
    return self;
}

- (void)dealloc
{
    if (self->zipFile != NULL) {
        unzClose(self->zipFile);
        self->zipFile = NULL;
    }
}

- (void)invalidateFileCache
{
    self->fileCache = nil;
}

- (FXZipFile *)findFileWithCRC:(NSUInteger)crc
{
    __block FXZipFile *matching = nil;
    [[self files] enumerateObjectsUsingBlock:^(FXZipFile *file, NSUInteger idx, BOOL *stop) {
        if ([file CRC] == crc) {
            matching = file;
            *stop = YES;
        }
    }];
    
    return matching;
}

- (FXZipFile *)findFileNamed:(NSString *)filename
              matchExactPath:(BOOL)exactPath
{
    __block FXZipFile *matching = nil;
    [[self files] enumerateObjectsUsingBlock:^(FXZipFile *file, NSUInteger idx, BOOL *stop) {
        NSString *path = [file filename];
        if (!exactPath) {
            path = [path lastPathComponent];
        }
        
        if ([path isEqualToString:filename]) {
            matching = file;
            *stop = YES;
        }
    }];
    
    return matching;
}

- (FXZipFile *)findFileNamedAnyOf:(NSArray *)filenames
                   matchExactPath:(BOOL)exactPath
{
    __block FXZipFile *matching = nil;
    [filenames enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger idx, BOOL *stop) {
        FXZipFile *file = [self findFileNamed:filename
                               matchExactPath:exactPath];
        if (file != nil) {
            matching = file;
            *stop = YES;
        }
    }];
    
    return matching;
}

- (BOOL)locateFileWithCRC:(NSUInteger)crc
                    error:(NSError **)error
{
    int rv = unzGoToFirstFile(self->zipFile);
    if (rv != UNZ_OK) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"org.akop.fbx.Zip"
                                         code:FXErrorNavigatingArchive
                                     userInfo:@{ NSLocalizedDescriptionKey : @"Error rewinding to first file in archive" }];
        }
        
        return NO;
    }
    
    NSUInteger count = [self fileCount];
    for (int i = 0; i < count; i++) {
        unz_file_info fileInfo;
        if (unzGetCurrentFileInfo(self->zipFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0) != UNZ_OK) {
            continue;
        }
        
        if (crc == fileInfo.crc) {
            return YES;
        }
        
        rv = unzGoToNextFile(self->zipFile);
        if (rv != UNZ_OK) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:@"org.akop.fbx.Zip"
                                             code:FXErrorNavigatingArchive
                                         userInfo:@{ NSLocalizedDescriptionKey : @"Error navigating files in the archive" }];
            }
            
            return NO;
        }
    }
    
    return NO;
}

- (UInt32)readFileWithCRC:(NSUInteger)crc
               intoBuffer:(void *)buffer
             bufferLength:(NSUInteger)length
                    error:(NSError **)error
{
    UInt32 bytesRead = -1;
    NSError *localError = NULL;
    
    if (![self locateFileWithCRC:crc
                           error:&localError]) {
        if (error != NULL && localError != NULL) {
            *error = localError;
        }
        
        return bytesRead;
    }
    
    int rv = unzOpenCurrentFile(self->zipFile);
    if (rv != UNZ_OK) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"org.akop.fbx.Zip"
                                         code:FXErrorOpeningCompressedFile
                                     userInfo:@{ NSLocalizedDescriptionKey : @"Error opening compressed file" }];
        }
        
        return bytesRead;
    }
    
    rv = unzReadCurrentFile(self->zipFile, buffer, (UInt32)length);
    if (rv < 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"org.akop.fbx.Zip"
                                         code:FXErrorReadingCompressedFile
                                     userInfo:@{ NSLocalizedDescriptionKey : @"Error reading compressed file" }];
        }
        
        return bytesRead;
    }
    
    bytesRead = rv;
    
    rv = unzCloseCurrentFile(self->zipFile);
    if (rv == UNZ_CRCERROR) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"org.akop.fbx.Zip"
                                         code:FXErrorReadingCompressedFile
                                     userInfo:@{ NSLocalizedDescriptionKey : @"CRC error" }];
        }
    }
    
    return bytesRead;
}

- (NSUInteger)fileCount
{
    NSUInteger count = 0;
    
    if (self->zipFile != NULL) {
        unz_global_info globalInfo;
        unzGetGlobalInfo(self->zipFile, &globalInfo);
        count = globalInfo.number_entry;
    }
    
    return count;
}

- (NSArray *)files
{
    if (self->fileCache == nil) {
        NSMutableArray *entries = [[NSMutableArray alloc] init];
        if (self->zipFile != NULL) {
            // Loop through files
            NSUInteger n = [self fileCount];
            for (int i = 0, rv = unzGoToFirstFile(self->zipFile);
                 i < n && rv == UNZ_OK;
                 i++, rv = unzGoToNextFile(self->zipFile)) {
                // Get individual file record
                unz_file_info fileInfo;
                if (unzGetCurrentFileInfo(self->zipFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0) != UNZ_OK) {
                    continue;
                }
                
                // Allocate space for the filename
                NSInteger filenameLen = fileInfo.size_filename + 1;
                char *cFilename = (char *)malloc(filenameLen);
                if (cFilename == NULL) {
                    continue;
                }
                
                if (unzGetCurrentFileInfo(self->zipFile, &fileInfo, cFilename, filenameLen, NULL, 0, NULL, 0) != UNZ_OK) {
                    free(cFilename);
                    continue;
                }
                
                FXZipFile *file = [[FXZipFile alloc] init];
                [file setFilename:[NSString stringWithCString:cFilename
                                                     encoding:NSUTF8StringEncoding]];
                [file setCRC:(UInt32)fileInfo.crc];
                [file setLength:fileInfo.uncompressed_size];
                
                free(cFilename);
                
                [entries addObject:file];
            }
        }
        
        self->fileCache = entries;
    }
    
    return [NSArray arrayWithArray:self->fileCache];
}

@end
