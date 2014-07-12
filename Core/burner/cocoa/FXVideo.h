/*****************************************************************************
 **
 ** FinalBurn X: Port of FinalBurn to OS X
 ** https://github.com/pokebyte/FinalBurnX
 ** Copyright (C) 2014 Akop Karapetyan
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
#import <Foundation/Foundation.h>

@protocol FXVideoDelegate<NSObject>

@optional
- (void)screenSizeDidChange:(NSSize)newSize;
- (void)initTextureOfWidth:(int)width
                    height:(int)height
                 isRotated:(BOOL)rotated
             bytesPerPixel:(int)bytesPerPixel;
- (void)renderFrame:(unsigned char *)bitmap;

@end

@interface FXVideo : NSObject
{
    @private
    NSMutableArray *observers;
    NSLock *observerLock;
    
    unsigned char *screenBuffer;
    int bufferWidth;
    int bufferHeight;
    int bufferBytesPerPixel;
}

- (void)addObserver:(id<FXVideoDelegate>)observer;
- (void)removeObserver:(id<FXVideoDelegate>)observer;

@end
