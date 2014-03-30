//
//  ARMHeaderViewWithActivityIndicator.h
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/29/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ARMTableHeaderViewWithActivityIndicator : UIView

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityInidcator;

@end
