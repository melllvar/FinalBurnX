/*****************************************************************************
 **
 ** FinalBurn X: Port of FinalBurn to OS X
 ** https://github.com/pokebyte/FinalBurnX
 ** Copyright (C) 2014-2016 Akop Karapetyan
 **
 ** This program is free software; you can redistribute it and/or modify
 ** it under the terms of the GNU General Public License as published by
 ** the Free Software Foundation; either version 2 of the License, or
 ** (at your option) any later version.
 **
 ** This program is distributed in the hope that it will be useful,
 ** but WITHOUT ANY WARRANTY; without even the implied warranty of
 ** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ** GNU General Public License for more details.
 **
 ** You should have received a copy of the GNU General Public License
 ** along with this program; if not, write to the Free Software
 ** Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 **
 ******************************************************************************
 */
#import "FXVideo.h"

#include "burner.h"

#import "FXEmulator.h"

@interface FXVideo ()

- (void) cleanup;

@end

@implementation FXVideo
{
	unsigned char *_buffer;
	int _bufferSize;
	CVPixelBufferRef _pixelBuffer;
	IOSurfaceRef _surfaceRef;
	int _screenWidth;
	int _screenHeight;
}

#pragma mark - Init and dealloc

- (instancetype) init
{
    if (self = [super init]) {
		self->_buffer = NULL;
		self->_pixelBuffer = NULL;
		self->_surfaceRef = NULL;
    }

    return self;
}

- (void) dealloc
{
    [self cleanup];
}

#pragma mark - Core callbacks

- (BOOL) initCore
{
    int rotationMode = 0;
    BurnDrvGetVisibleSize(&self->_screenWidth, &self->_screenHeight);
	
    if (BurnDrvGetFlags() & BDF_ORIENTATION_VERTICAL) {
        rotationMode |= 1;
    }
    
    if (BurnDrvGetFlags() & BDF_ORIENTATION_FLIPPED) {
        rotationMode ^= 2;
    }
    
    nVidImageDepth = 24;
	nVidImageBPP = 3;
	nVidImageWidth = self->_screenWidth;
	nVidImageHeight = self->_screenHeight;
	
	if (!rotationMode) {
		nVidImagePitch = nVidImageWidth * nVidImageBPP;
	} else {
		nVidImagePitch = nVidImageHeight * nVidImageBPP;
	}
	
	SetBurnHighCol(nVidImageDepth);
	
    self->_bufferSize = nVidImageWidth * nVidImageHeight * nVidImageBPP;
    @synchronized(self) {
        free(self->_buffer);
        self->_buffer = (unsigned char *) malloc(self->_bufferSize);
    }
    
    if (self->_buffer == NULL) {
        return NO;
    }
	
	nBurnBpp = nVidImageBPP;
	nBurnPitch = nVidImagePitch;
    pVidImage = self->_buffer;
    
    memset(self->_buffer, 0, self->_bufferSize);
	
	NSDictionary *attrs = @{
							(NSString *) kCVPixelBufferPixelFormatTypeKey: @(k24RGBPixelFormat),
							(NSString *) kCVPixelBufferIOSurfacePropertiesKey: @{
									(NSString *) kIOSurfaceIsGlobal: @(YES), // FIXME
									},
							(NSString *) kCVPixelBufferOpenGLCompatibilityKey: @(YES),
							};
	CVReturn rv = CVPixelBufferCreate(kCFAllocatorDefault, nVidImageWidth, nVidImageHeight,
									  k24RGBPixelFormat, (__bridge CFDictionaryRef) attrs, &self->_pixelBuffer);
	if (rv != kCVReturnSuccess) {
		NSLog(@"FXVideo: CVPixelBufferCreate failed (got %i)", rv);
		free(self->_buffer);
		return NO;
	}
	
	self->_surfaceRef = CVPixelBufferGetIOSurface(self->_pixelBuffer);
	self->_surfaceId = IOSurfaceGetID(self->_surfaceRef);
	
	NSLog(@"video/init done");
	
    return YES;
}

- (BOOL) renderFrame:(BOOL) redraw
{
	if (pVidImage == NULL) {
		return NO;
	}
	
    if (redraw) {
        if (BurnDrvRedraw()) {
            BurnDrvFrame();
        }
    } else {
        BurnDrvFrame();
	}
    
	return YES;
}

- (BOOL) renderToSurface:(BOOL) validate
{
	IOSurfaceLock(self->_surfaceRef, 0, NULL);
	memcpy(IOSurfaceGetBaseAddress(self->_surfaceRef), self->_buffer, self->_bufferSize);
	IOSurfaceUnlock(self->_surfaceRef, 0, NULL);
	
    return YES;
}

#pragma mark - Private

- (void) cleanup
{
    @synchronized(self) {
        free(self->_buffer);
        self->_buffer = NULL;
		CVPixelBufferRelease(self->_pixelBuffer);
		self->_pixelBuffer = NULL;
    }
}

@end

#pragma mark - FinalBurn callbacks

static int cocoaVideoInit()
{
    FXVideo *video = [[FXEmulator sharedInstance] video];
    return [video initCore] ? 0 : 1;
}

static int cocoaVideoExit()
{
	FXVideo *video = [[FXEmulator sharedInstance] video];
    [video cleanup];
    
    return 0;
}

static int cocoaVideoFrame(bool redraw)
{
	FXVideo *video = [[FXEmulator sharedInstance] video];
    return [video renderFrame:redraw] ? 0 : 1;
}

static int cocoaVideoPaint(int validate)
{
	FXVideo *video = [[FXEmulator sharedInstance] video];
    return [video renderToSurface:(validate & 2)] ? 0 : 1;
}

struct VidOut VidOutCocoa = {
    cocoaVideoInit,
    cocoaVideoExit,
    cocoaVideoFrame,
    cocoaVideoPaint,
    NULL,
    NULL,
    "Cocoa Video",
};
