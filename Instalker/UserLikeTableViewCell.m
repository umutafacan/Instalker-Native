//
//  UserLikeTableViewCell.m
//  Instalker
//
//  Created by umut on 1/31/16.
//  Copyright © 2016 SmartClick. All rights reserved.
//

#import "UserLikeTableViewCell.h"

@implementation UserLikeTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setFields:(UserLikeCountModel *)model
{
    _labelFullname.text=model.user.fullName;
    _labelLikeCount.text=[NSString stringWithFormat:NSLocalizedString(@"%@ likes", nil), model.likeCount];
    _labelUsername.text=model.user.username;
    _imageViewProfile.image= [UIImage imageNamed:@"anonymousUser"];
    _imageViewProfile.imageURL=model.user.profilePictureURL;
    _user=model.user;
    _arrayLikedMedias = [NSArray arrayWithArray:model.arrayMedias];
}




@end
