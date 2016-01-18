//
//  UIView+MASAdditions.m
//  Masonry
//
//  Created by Jonas Budelmann on 20/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "View+MASAdditions.h"
#import <objc/runtime.h>
#import "MASLayoutConstraint.h"
#import "MASViewConstraint.h"

@implementation MAS_VIEW (MASAdditions)

- (NSArray *)mas_makeConstraints:(void(^)(MASConstraintMaker *))block {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    MASConstraintMaker *constraintMaker = [[MASConstraintMaker alloc] initWithView:self];
    block(constraintMaker);
    return [constraintMaker install];
}

- (NSArray *)mas_updateConstraints:(void(^)(MASConstraintMaker *))block {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    MASConstraintMaker *constraintMaker = [[MASConstraintMaker alloc] initWithView:self];
    constraintMaker.updateExisting = YES;
    block(constraintMaker);
    return [constraintMaker install];
}

- (NSArray *)mas_remakeConstraints:(void(^)(MASConstraintMaker *make))block {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    MASConstraintMaker *constraintMaker = [[MASConstraintMaker alloc] initWithView:self];
    constraintMaker.removeExisting = YES;
    block(constraintMaker);
    return [constraintMaker install];
}

#pragma mark - NSLayoutAttribute properties

- (MASViewAttribute *)mas_left {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLeft];
}

- (MASViewAttribute *)mas_top {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeTop];
}

- (MASViewAttribute *)mas_right {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeRight];
}

- (MASViewAttribute *)mas_bottom {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeBottom];
}

- (MASViewAttribute *)mas_leading {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLeading];
}

- (MASViewAttribute *)mas_trailing {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeTrailing];
}

- (MASViewAttribute *)mas_width {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeWidth];
}

- (MASViewAttribute *)mas_height {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeHeight];
}

- (MASViewAttribute *)mas_centerX {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeCenterX];
}

- (MASViewAttribute *)mas_centerY {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeCenterY];
}

- (MASViewAttribute *)mas_baseline {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeBaseline];
}

- (MASViewAttribute *(^)(NSLayoutAttribute))mas_attribute
{
    return ^(NSLayoutAttribute attr) {
        return [[MASViewAttribute alloc] initWithView:self layoutAttribute:attr];
    };
}

#if TARGET_OS_IPHONE || TARGET_OS_TV

- (MASViewAttribute *)mas_leftMargin {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLeftMargin];
}

- (MASViewAttribute *)mas_rightMargin {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeRightMargin];
}

- (MASViewAttribute *)mas_topMargin {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeTopMargin];
}

- (MASViewAttribute *)mas_bottomMargin {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeBottomMargin];
}

- (MASViewAttribute *)mas_leadingMargin {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLeadingMargin];
}

- (MASViewAttribute *)mas_trailingMargin {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeTrailingMargin];
}

- (MASViewAttribute *)mas_centerXWithinMargins {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeCenterXWithinMargins];
}

- (MASViewAttribute *)mas_centerYWithinMargins {
    return [[MASViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeCenterYWithinMargins];
}

#endif

#pragma mark - associated properties

- (id)mas_key {
    return objc_getAssociatedObject(self, @selector(mas_key));
}

- (void)setMas_key:(id)key {
    objc_setAssociatedObject(self, @selector(mas_key), key, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - heirachy

- (instancetype)mas_closestCommonSuperview:(MAS_VIEW *)view {
    MAS_VIEW *closestCommonSuperview = nil;

    MAS_VIEW *secondViewSuperview = view;
    while (!closestCommonSuperview && secondViewSuperview) {
        MAS_VIEW *firstViewSuperview = self;
        while (!closestCommonSuperview && firstViewSuperview) {
            if (secondViewSuperview == firstViewSuperview) {
                closestCommonSuperview = secondViewSuperview;
            }
            firstViewSuperview = firstViewSuperview.superview;
        }
        secondViewSuperview = secondViewSuperview.superview;
    }
    return closestCommonSuperview;
}

@end

#pragma mark - adapter

@interface UIView (Adapter)

@end

@implementation UIView (Adapter)

+ (void)load {
    Method oldMethod = class_getInstanceMethod(self, @selector(addConstraint:));
    Method newMethod = class_getInstanceMethod(self, @selector(adapter_addConstraint:));
    method_exchangeImplementations(oldMethod, newMethod);
}

- (void)adapter_addConstraint:(NSLayoutConstraint *)constraint {
    
    BOOL dontAdapter = NO;
    
    Class _UILayoutGuideClass = NSClassFromString(@"_UILayoutGuide");
    
    //filter _UILayoutGuide
    if ([constraint.firstItem isKindOfClass:_UILayoutGuideClass]) {
        dontAdapter = YES;
    }
    
    if ([self adapter_checkKeyboardView:constraint.firstItem] ||
        [self adapter_checkKeyboardView:constraint.secondItem]) {
        dontAdapter = YES;
    }
    
    if (dontAdapter) {
        [self adapter_addConstraint:constraint];
        return;
    }
    
    if ([constraint isMemberOfClass:[NSLayoutConstraint class]]) {
        NSLayoutConstraint *newConstraint
        = [MASLayoutConstraint constraintWithItem:constraint.firstItem
                                        attribute:constraint.firstAttribute
                                        relatedBy:constraint.relation
                                           toItem:constraint.secondItem
                                        attribute:constraint.secondAttribute
                                       multiplier:constraint.multiplier
                                         constant:constraint.constant];
        
        newConstraint.priority = constraint.priority;
        
        MASViewAttribute *firstAttribute = [[MASViewAttribute alloc] initWithView:newConstraint.firstItem
                                                                  layoutAttribute:newConstraint.firstAttribute];
        MASViewConstraint *masConstraint = [[MASViewConstraint alloc] initWithFirstViewAttribute:firstAttribute];
        if (newConstraint.secondItem && newConstraint.secondAttribute) {
            MASViewAttribute *secondAttribute = [[MASViewAttribute alloc] initWithView:newConstraint.secondItem
                                                                       layoutAttribute:newConstraint.secondAttribute];
            [masConstraint setValue:secondAttribute forKey:@"_secondViewAttribute"];
        }
        
        
        [masConstraint setValue:self forKey:@"installedView"];
        [masConstraint setValue:newConstraint forKey:@"layoutConstraint"];
        MAS_VIEW *firstItemView = newConstraint.firstItem;
        NSMutableSet *installedConstraints = [firstItemView valueForKey:@"mas_installedConstraints"];
        [installedConstraints addObject:masConstraint];
        
        [self adapter_addConstraint:newConstraint];
        return;
    }
    
    
    [self adapter_addConstraint:constraint];
    
}

- (BOOL)adapter_checkKeyboardView:(id)item {
    if ([item isKindOfClass:NSClassFromString(@"UIInputSetHostView")] ||
        [item isKindOfClass:NSClassFromString(@"UIInputSetContainerView")] ||
        [item isKindOfClass:NSClassFromString(@"UITextEffectsWindow")]) {
        return YES;
    }
    return NO;
}


@end



