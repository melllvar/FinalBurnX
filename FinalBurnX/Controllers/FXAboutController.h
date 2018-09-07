/*****************************************************************************
 **
 ** FinalBurn X: FinalBurn for macOS
 ** https://github.com/0xe1f/FinalBurn-X
 ** Copyright (C) 2014-2018 Akop Karapetyan
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
#import <Cocoa/Cocoa.h>

@interface FXWhitePanelView : NSView

@end

@interface FXInvisibleScrollView : NSScrollView

@end

@interface FXAboutController : NSWindowController<NSWindowDelegate>
{
    IBOutlet NSTextField *versionNumberField;
    IBOutlet NSTextField *appNameField;
}

- (IBAction) openFbaLicense:(id) sender;
- (IBAction) openFbxLicense:(id) sender;

@end