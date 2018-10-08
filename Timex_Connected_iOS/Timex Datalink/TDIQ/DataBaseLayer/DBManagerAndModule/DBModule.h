//
//  DBModule.h


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DBModule : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (id)sharedInstance;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (NSManagedObject *) addOrUpdateRowInEntity:(NSString *)entityName
                     mockObject:(NSObject*)mockObject
                            key:(NSString *)key
                          value:(NSObject *) value;
- (NSManagedObject *) addOrUpdateRowInEntity:(NSString *)entityName
                                  mockObject:(NSObject*)mockObject
                                   predicate:(NSPredicate *)predicate;

- (NSFetchRequest*) getFetchRequestForPredicate:(NSPredicate *)predicate
                                         entity:(NSString *)entity;

- (NSManagedObject *) executeAndReturnOne:(NSFetchRequest *)fetchRequest;

- (NSArray *) executeAndReturnAll:(NSFetchRequest *)fetchRequest;

- (NSArray *) getDetailsUsingFetchReq:(NSString *)templateName
                           entityName:(NSString*)entityName;

- (NSArray *) getArrayFor:(NSPredicate *)predicate
               entityName: (NSString *)entityName;

- (NSArray *) getSortedArrayFor:(NSString *)entityName
                     predicate : (NSPredicate *)predicate
                      keyString: (NSString *)keyString
                    isAscending: (BOOL)isAscending;

- (NSArray *) getAllRecordsForEntity:(NSString *)entityName;

- (void) deleteWithFetchReq:(NSFetchRequest *)fetchRequest;

- (void) deleteAllRecordsInEntity:(NSString *)entityName;

- (void) deleteObj:(NSString *)entityName
        managedObj: (NSManagedObject *) managedObj;

- (void) deleteEntity:(NSString *)entityName
           columnName:(NSString *)columnName
                value:(NSObject *)value;

- (NSManagedObject *) getEntity:(NSString *)entityName
                     columnName:(NSString *)columnName
                          value:(NSObject*) value;
- (NSManagedObject *) getEntity:(NSString *)entityName
                  withPredicate:(NSPredicate *)predicate;
- (NSManagedObjectContext *)getManagedContext;
- (NSArray *) getAllRecordsForEntityToUpdateWatchID:(NSString *)entityName;
@end
