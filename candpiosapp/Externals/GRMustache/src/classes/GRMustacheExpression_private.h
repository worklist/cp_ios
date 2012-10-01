// The MIT License
// 
// Copyright (c) 2012 Gwendal Roué
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

#import <Foundation/Foundation.h>
#import "GRMustacheAvailabilityMacros_private.h"

@class GRMustacheRuntime;
@class GRMustacheToken;

/**
 * TODO
 *
 * The GRMustacheExpression is the protocol for objects that can provide values
 * out of the data provided by the library user.
 *
 * GRMustacheExpression instances are built by GRMustacheParser. For instance,
 * the `{{ name }}` tag would yield a GRMustacheIdentifierExpression.
 *
 * @see GRMustacheFilteredExpression
 * @see GRMustacheIdentifierExpression
 * @see GRMustacheImplicitIteratorExpression
 * @see GRMustacheScopedExpression
 */
@interface GRMustacheExpression : NSObject {
@private
    GRMustacheToken *_token;
}

/**
 * TODO
 * This property stores a token whose sole purpose is to help the library user
 * debugging his templates, using the tokens' ability to output their location
 * (`{{ foo }} at line 23 of /path/to/template`).
 */
@property (nonatomic, retain) GRMustacheToken *token;

/**
 * TODO
 */
- (id)evaluateInRuntime:(GRMustacheRuntime *)runtime asFilterValue:(BOOL)filterValue;

@end
