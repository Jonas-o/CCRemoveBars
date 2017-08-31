//
//  UITextInputAssistantItem+CCRemoveBars.m
//  ecloud-ios
//
//  Created by luo on 2017/8/31.
//  Copyright © 2017年 ecloud. All rights reserved.
//

#import "UITextInputAssistantItem+CCRemoveBars.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString *const kCCClassPrefix = @"CCClassPrefix_";

#pragma mark - Overridden Methods
static NSArray<UIBarButtonItemGroup *> * leadingBarButtonGroups_getter(id self, SEL _cmd)
{
    return @[];
}

static NSArray<UIBarButtonItemGroup *> * trailingBarButtonGroups_getter(id self, SEL _cmd)
{
    return @[];
}

static Class sub_class(id self, SEL _cmd)
{
    return class_getSuperclass(object_getClass(self));
}

@implementation UITextInputAssistantItem (CCRemoveBars)

- (NSArray<UIBarButtonItemGroup *> *)leadingBarButtonGroups
{
    return @[];
}

- (NSArray<UIBarButtonItemGroup *> *)trailingBarButtonGroups
{
    return @[];
}

- (void)removeBarsOrNot:(BOOL)remove {
    if (!remove) {
        return;
    }
    NSString *leadingBarGetter = @"leadingBarButtonGroups";
    
    SEL leadingBarSelector = NSSelectorFromString(leadingBarGetter);
    Method leadingBarMethod = class_getInstanceMethod([self class], leadingBarSelector);
    if (!leadingBarMethod) {
#ifdef DEBUG
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have method %@", self, leadingBarGetter];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
#endif
        return;
    }
    
    NSString *trailingBarGetter = @"trailingBarButtonGroups";
    
    SEL trailingBarSelector = NSSelectorFromString(trailingBarGetter);
    Method trailingBarMethod = class_getInstanceMethod([self class], trailingBarSelector);
    if (!trailingBarMethod) {
#ifdef DEBUG
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have method %@", self, trailingBarGetter];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
#endif
        return;
    }
    
    Class clazz = object_getClass(self);
    NSString *clazzName = NSStringFromClass(clazz);
    
    // if not an sub class yet
    if (![clazzName hasPrefix:kCCClassPrefix]) {
        clazz = [self makeSubClassWithOriginalClassName:clazzName];
        object_setClass(self, clazz);
    }
    
    // add our sub getter if this class (not superclasses) doesn't implement the getter?
    if (![self hasSelector:leadingBarSelector]) {
        const char *types = method_getTypeEncoding(leadingBarMethod);
        class_addMethod(clazz, leadingBarSelector, (IMP)leadingBarButtonGroups_getter, types);
    }
    
    // add our sub getter if this class (not superclasses) doesn't implement the getter?
    if (![self hasSelector:trailingBarSelector]) {
        const char *types = method_getTypeEncoding(trailingBarMethod);
        class_addMethod(clazz, trailingBarSelector, (IMP)trailingBarButtonGroups_getter, types);
    }
    
}

- (Class)makeSubClassWithOriginalClassName:(NSString *)originalClazzName
{
    NSString *kvoClazzName = [kCCClassPrefix stringByAppendingString:originalClazzName];
    Class clazz = NSClassFromString(kvoClazzName);
    
    if (clazz) {
        return clazz;
    }
    
    // class doesn't exist yet, make it
    Class originalClazz = object_getClass(self);
    Class kvoClazz = objc_allocateClassPair(originalClazz, kvoClazzName.UTF8String, 0);
    
    // grab class method's signature so we can borrow it
    Method clazzMethod = class_getInstanceMethod(originalClazz, @selector(class));
    const char *types = method_getTypeEncoding(clazzMethod);
    class_addMethod(kvoClazz, @selector(class), (IMP)sub_class, types);
    
    objc_registerClassPair(kvoClazz);
    
    return kvoClazz;
}

- (BOOL)hasSelector:(SEL)selector
{
    Class clazz = object_getClass(self);
    unsigned int methodCount = 0;
    Method* methodList = class_copyMethodList(clazz, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == selector) {
            free(methodList);
            return YES;
        }
    }
    
    free(methodList);
    return NO;
}

@end
