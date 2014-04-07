//
//  ARMHeaderViewWithActivityIndicator.h
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/29/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARMTableHeaderContentView.h"

@interface ARMTableHeaderViewWithActivityIndicator : UITableViewHeaderFooterView

@property (weak, nonatomic) ARMTableHeaderContentView *ARMContentView;

@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) UILabel *titleLabel;

@end

