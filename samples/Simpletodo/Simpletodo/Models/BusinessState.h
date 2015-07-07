//
//  BusinessState.h
//  Simpletodo
//
//  Created by anshuqiang on 15/7/7.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <Simperium/SPManagedObject.h>


@interface BusinessState : SPManagedObject

@property (nonatomic, retain) NSNumber * code;
@property (nonatomic, retain) NSString * company_id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * isopen;
@property (nonatomic, retain) NSString * update_time;
@property (nonatomic, retain) NSString * identifier;

@end
