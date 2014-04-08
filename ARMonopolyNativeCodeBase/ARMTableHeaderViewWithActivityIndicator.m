//
//  ARMHeaderViewWithActivityIndicator.m
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/29/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import "ARMTableHeaderViewWithActivityIndicator.h"
#import "ARMTableHeaderContentView.h"

const NSString *ARMReuseIdentifierForTableViewHeaderWithActivityIndicator = @"ARMReuseIdentifierForTableViewHeaderWithActivityIndicator";

@implementation ARMTableHeaderViewWithActivityIndicator

@synthesize activityIndicator;
@synthesize titleLabel;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self initImpl];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self initImpl];
    }
    return self;
}

- (void)initImpl
{
    
    UINib *contentViewNib = [UINib nibWithNibName:@"ARMSectionHeaderView" bundle:nil];
    
    self.ARMContentView = [[contentViewNib instantiateWithOwner:nil options:nil] firstObject];
    self.activityIndicator = self.ARMContentView.activityIndicator;
    titleLabel = self.ARMContentView.titleLabel;
    
    [titleLabel setText:@"YAY"];
    
    [activityIndicator setHidesWhenStopped:YES];
    [activityIndicator setHidden:YES];
    
    [self.contentView addSubview:self.ARMContentView];
}

- (void)setTitleLabelText:(NSString *)newTitle
{
//    self.ARMContentView.titleLabel.text = newTitle;
}

@end
