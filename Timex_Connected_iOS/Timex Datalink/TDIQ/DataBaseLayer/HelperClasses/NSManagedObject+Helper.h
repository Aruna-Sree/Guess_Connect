//
//  NSManagedObject+Helper.h
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSManagedObject (Helper)

- (void) saveDetailsInDB:(id)details;

- (void) updateDetailsInDB:(id)details;

@end
