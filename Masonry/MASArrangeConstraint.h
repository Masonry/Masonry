//
//  Copyright (c) 2014 Alexey Afanasev. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "MASViewConstraint.h"


@interface MASArrangeConstraint : MASConstraint <MASConstraintDelegate>

- (id)initWith:(NSArray *)array;

// Create an array of constraints using an ASCII art-like visual format string.
// views are labeled as v1, v2,...
- (MASConstraint * (^)(id))ascii;

@property(nonatomic) BOOL isVertical;

@end