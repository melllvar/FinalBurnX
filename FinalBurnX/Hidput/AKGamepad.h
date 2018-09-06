/*****************************************************************************
 **
 ** FinalBurn X: FinalBurn for macOS
 ** https://github.com/pokebyte/FinalBurn-X
 ** Copyright (C) 2014-2016 Akop Karapetyan
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
#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>

@interface AKGamepad : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic, assign) NSInteger gamepadId;
@property (nonatomic, assign) NSUInteger index;

@property (nonatomic, readonly) NSInteger locationId;
@property (nonatomic, readonly) NSInteger vendorId;
@property (nonatomic, readonly) NSInteger productId;
@property (nonatomic, readonly) NSString *name;

- (id) initWithHidDevice:(IOHIDDeviceRef) device;

- (void) registerForEvents;

- (NSInteger) vendorProductId;
- (NSString *) vendorProductString;

- (NSMutableDictionary *) currentAxisValues;

@end