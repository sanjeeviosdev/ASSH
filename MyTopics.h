//
//  MyTopics.h
//  ASSH
//
//  Created by Sanjeev Jha on 10/04/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MyTopics : NSManagedObject

@property (nonatomic, retain) NSString * bookName;
@property (nonatomic, retain) NSString * content;
@property (nonatomic) int32_t indexOnPage;

//+ (MyTopics *) getMarkedTopics;

@end
