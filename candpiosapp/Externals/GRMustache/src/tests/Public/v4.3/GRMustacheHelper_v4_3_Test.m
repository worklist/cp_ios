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

#define GRMUSTACHE_VERSION_MAX_ALLOWED GRMUSTACHE_VERSION_5_0
#import "GRMustachePublicAPITest.h"

@interface GRMustacheHelper_v4_3_Test : GRMustachePublicAPITest
@end



@interface GRMustacheSectionAlternateTemplateStringRenderingHelper : NSObject<GRMustacheHelper> {
    NSString *_templateString;
}
@property (nonatomic, copy) NSString *templateString;
@end

@implementation GRMustacheSectionAlternateTemplateStringRenderingHelper
@synthesize templateString=_templateString;

- (void)dealloc
{
    self.templateString = nil;
    [super dealloc];
}

- (NSString *)renderSection:(GRMustacheSection *)section
{
    return [section renderTemplateString:self.templateString error:NULL];
}

@end



@interface GRMustacheSectionRenderingHelper : NSObject<GRMustacheHelper>
@end

@implementation GRMustacheSectionRenderingHelper

- (NSString *)renderSection:(GRMustacheSection *)section
{
    return [section render];
}

@end



@interface GRMustacheHelperTemplateDelegate_v4_3 : NSObject<GRMustacheTemplateDelegate>
@end

@implementation GRMustacheHelperTemplateDelegate_v4_3

- (void)template:(GRMustacheTemplate *)template willInterpretReturnValueOfInvocation:(GRMustacheInvocation *)invocation as:(GRMustacheInterpretation)interpretation
{
    if (interpretation != GRMustacheInterpretationSection) {
        invocation.returnValue = @"delegate";
    }
}

@end

@implementation GRMustacheHelper_v4_3_Test

- (void)testHelperCanRenderCurrentContextInDistinctTemplate
{
    // This test is against Mustache spec lambda definition, which do not have access to the current rendering context.
    
    {
        // GRMustacheHelper protocol
        GRMustacheSectionAlternateTemplateStringRenderingHelper *helper = [[[GRMustacheSectionAlternateTemplateStringRenderingHelper alloc] init] autorelease];
        helper.templateString = @"{{subject}}";
        NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:
                                 helper, @"helper",
                                 @"---", @"subject", nil];
        NSString *result = [GRMustacheTemplate renderObject:context fromString:@"{{#helper}}{{/helper}}" error:nil];
        STAssertEqualObjects(result, @"---", @"");
    }
    {
        // [GRMustacheHelper helperWithBlock:]
        id helper = [GRMustacheHelper helperWithBlock:^NSString *(GRMustacheSection *section) {
            return [section renderTemplateString:@"{{subject}}" error:NULL];
        }];
        NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:
                                 helper, @"helper",
                                 @"---", @"subject", nil];
        NSString *result = [GRMustacheTemplate renderObject:context fromString:@"{{#helper}}{{/helper}}" error:nil];
        STAssertEqualObjects(result, @"---", @"");
    }
}

- (void)testTemplateDelegateCallbacksAreCalledWithinSectionRendering
{
    {
        // GRMustacheHelper protocol
        GRMustacheSectionRenderingHelper *helper = [[[GRMustacheSectionRenderingHelper alloc] init] autorelease];
        NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:
                                 helper, @"helper",
                                 @"---", @"subject", nil];
        GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{#helper}}{{subject}}{{/helper}}" error:NULL];
        template.delegate = [[[GRMustacheHelperTemplateDelegate_v4_3 alloc] init] autorelease];
        NSString *result = [template renderObject:context];
        STAssertEqualObjects(result, @"delegate", @"");
    }
    {
        // [GRMustacheHelper helperWithBlock:]
        id helper = [GRMustacheHelper helperWithBlock:^NSString *(GRMustacheSection *section) {
            return [section render];
        }];
        NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:
                                 helper, @"helper",
                                 @"---", @"subject", nil];
        GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{#helper}}{{subject}}{{/helper}}" error:NULL];
        template.delegate = [[[GRMustacheHelperTemplateDelegate_v4_3 alloc] init] autorelease];
        NSString *result = [template renderObject:context];
        STAssertEqualObjects(result, @"delegate", @"");
    }
}


- (void)testTemplateDelegateCallbacksAreCalledWithinSectionAlternateTemplateStringRendering
{
    {
        // GRMustacheHelper protocol
        GRMustacheSectionAlternateTemplateStringRenderingHelper *helper = [[[GRMustacheSectionAlternateTemplateStringRenderingHelper alloc] init] autorelease];
        helper.templateString = @"{{subject}}";
        NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:
                                 helper, @"helper",
                                 @"---", @"subject", nil];
        GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{#helper}}{{/helper}}" error:NULL];
        template.delegate = [[[GRMustacheHelperTemplateDelegate_v4_3 alloc] init] autorelease];
        NSString *result = [template renderObject:context];
        STAssertEqualObjects(result, @"delegate", @"");
    }
    {
        // [GRMustacheHelper helperWithBlock:]
        id helper = [GRMustacheHelper helperWithBlock:^NSString *(GRMustacheSection *section) {
            return [section renderTemplateString:@"{{subject}}" error:NULL];
        }];
        NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:
                                 helper, @"helper",
                                 @"---", @"subject", nil];
        GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{#helper}}{{/helper}}" error:NULL];
        template.delegate = [[[GRMustacheHelperTemplateDelegate_v4_3 alloc] init] autorelease];
        NSString *result = [template renderObject:context];
        STAssertEqualObjects(result, @"delegate", @"");
    }
}

@end
