// ACEOAuth2RACManagerPrivate.h
//
// Copyright (c) 2016 Stefano Acerbetti - https://github.com/acerbetti/ACEOAuth2RACManager
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


/**
 *  Automatically detect if CocoaLumberJack is available and if so use
 *  it as a logging facility.
 */

#if defined(__has_include) && __has_include("CocoaLumberjack/CocoaLumberjack.h")

#import <CocoaLumberjack/CocoaLumberjack.h>

#define __DDLOG_ENABLED__ 1

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF ACELogLevel
extern const DDLogLevel ACELogLevel;

#define ACE_LOG_DEBUG(...)      DDLogDebug(__VA_ARGS__)
#define ACE_LOG_VERBOSE(...)    DDLogVerbose(__VA_ARGS__)
#define ACE_LOG_INFO(...)       DDLogInfo(__VA_ARGS__)
#define ACE_LOG_WARNING(...)    DDLogWarn(__VA_ARGS__)
#define ACE_LOG_ERROR(...)      DDLogError(__VA_ARGS__)

#else

#define ACE_LOG_DEBUG(...)      NSLog(__VA_ARGS__)
#define ACE_LOG_VERBOSE(...)    NSLog(__VA_ARGS__)
#define ACE_LOG_INFO(...)       NSLog(__VA_ARGS__)
#define ACE_LOG_WARNING(...)    NSLog(__VA_ARGS__)
#define ACE_LOG_ERROR(...)      NSLog(__VA_ARGS__)

#endif
