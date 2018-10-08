//
//  DBModule.m
//

#import "DBModule.h"
#import "NSManagedObject+Helper.h"
#import "DBActivity+CoreDataClass.h"
#import "DBSleepEvents.h"
#import "DBHourActivity+CoreDataClass.h"
#import "iDevicesUtil.h"
#import "ActivityModal.h"
#import "SleepEventsModal.h"
#import "HourActivityModal.h"

@implementation DBModule

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


static DBModule *dbModlue = nil;

+ (id)sharedInstance
{
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        dbModlue = [[DBModule alloc] init];
    });
    return dbModlue;
}

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.innominds.SampleDB" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SampleDB.sqlite"];
    NSError *error = nil;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


- (NSManagedObject *) addOrUpdateRowInEntity:(NSString *)entityName
                     mockObject:(NSObject*)mockObject
                            key:(NSString *)key
                          value:(NSObject *) value
{
    if (entityName == nil)
    {
        return nil;
    }
    if (mockObject == nil)
    {
        return nil;
    }
    
    NSManagedObject *object = nil;
    
    if (key != nil && value != nil)
    {
        object = [self getEntity:entityName columnName:key value:value];
    }
    if (object == nil)
    {
        object = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
        
        if ([object respondsToSelector:@selector(saveDetailsInDB:)])
        {
            [object saveDetailsInDB:mockObject];
        }
    }
    
    else
    {
        if ([object respondsToSelector:@selector(updateDetailsInDB:)])
        {
            [object updateDetailsInDB:mockObject];
        }
    }
    [self saveContext];
    return object;
}

- (NSManagedObject *) addOrUpdateRowInEntity:(NSString *)entityName
                                  mockObject:(NSObject*)mockObject
                                   predicate:(NSPredicate *)predicate
{
    if (entityName == nil)
    {
        return nil;
    }
    if (mockObject == nil)
    {
        return nil;
    }
    if (predicate == nil) {
        return nil;
    }
    NSManagedObject *object = nil;
    
    object = [self getEntity:entityName withPredicate:predicate];
    if (object == nil)
    {
        object = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
        
        if ([object respondsToSelector:@selector(saveDetailsInDB:)])
        {
            [object saveDetailsInDB:mockObject];
        }
    }
    
    else
    {
        if ([object respondsToSelector:@selector(updateDetailsInDB:)])
        {
            [object updateDetailsInDB:mockObject];
        }
    }
    [self saveContext];
    return object;
}

// MARK:- Fetching
- (NSFetchRequest*) getFetchRequestForPredicate:(NSPredicate *)predicate
                                         entity:(NSString *)entity
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:entity inManagedObjectContext:self.managedObjectContext];
    
    NSString * storedUUID = [iDevicesUtil getWatchID];
    NSPredicate * newCondition = [NSPredicate predicateWithFormat:@"watchID==%@", storedUUID];
    if(predicate != nil) {
        NSPredicate * newPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate, newCondition, nil]];
        fetchRequest.predicate = newPredicate;
    } else {
        fetchRequest.predicate = newCondition;
    }
    return fetchRequest;
}

- (NSManagedObject *) executeAndReturnOne:(NSFetchRequest *)fetchRequest
{
    if (fetchRequest == nil)
    {
        NSLog(@"nil fetch request found");
        return nil;
    }
    
    NSError *error = nil;
    
    NSArray* data_ = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if(data_.count > 1)
    {
        NSLog(@"solve this bug");
    }
    
    if(data_.count > 0)
    {
        return [data_ objectAtIndex:0];
    }
    else
    {
        return nil;
    }
    return nil;
}

- (NSArray *) executeAndReturnAll:(NSFetchRequest *)fetchRequest
{
    NSError *requestError = nil;
    
    NSArray* arr = [self.managedObjectContext executeFetchRequest:fetchRequest
                                                            error:&requestError];
   
    if (arr.count > 0) {
        return arr;
    }
    else
    {
        return [[NSArray alloc] init];
    }
}

//used to process the predefined fetch request
- (NSArray *) getDetailsUsingFetchReq:(NSString *)templateName
                           entityName:(NSString*)entityName
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    
    NSFetchRequest *fetchRequest = [[model fetchRequestTemplateForName:templateName] copy];
    //NSDictionary *temp = [NSDictionary new];
   // NSFetchRequest *fetchRequest = [[model fetchRequestFromTemplateWithName:templateName substitutionVariables:temp] copy];
    
    fetchRequest.entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    return [self executeAndReturnAll:fetchRequest];
}

- (NSArray *) getArrayFor:(NSPredicate *)predicate
               entityName: (NSString *)entityName
{
    NSFetchRequest *fetchRequest = [self getFetchRequestForPredicate:predicate entity:entityName];
    return [self executeAndReturnAll:fetchRequest];
}

- (NSArray *) getSortedArrayFor:(NSString *)entityName
                     predicate : (NSPredicate *)predicate
                      keyString: (NSString *)keyString
                    isAscending: (BOOL)isAscending
{
    NSFetchRequest *fetchRequest = [self getFetchRequestForPredicate:predicate entity:entityName];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:keyString ascending:isAscending];
    NSArray *sortDescriptors = @[sortDescriptor];
    fetchRequest.sortDescriptors = sortDescriptors;
    return [self executeAndReturnAll:fetchRequest];
}

//get all records from the db for specified entity
- (NSArray *) getAllRecordsForEntity:(NSString *)entityName
{
    NSFetchRequest *fetchRequest = [self getFetchRequestForPredicate:nil entity:entityName];
    return [self executeAndReturnAll:fetchRequest];
}

- (NSArray *) getAllRecordsForEntityToUpdateWatchID:(NSString *)entityName
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate * newCondition = [NSPredicate predicateWithFormat:@"watchID==%@", nil];
    fetchRequest.predicate = newCondition;
    fetchRequest.entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    return [self executeAndReturnAll:fetchRequest];
}

// MARK:- Deleting
- (void) deleteWithFetchReq:(NSFetchRequest *)fetchRequest
{
    NSError *error = nil;
    NSArray *arr = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
  
    for (NSObject *row in arr)
    {
        [self.managedObjectContext deleteObject:(NSManagedObject*)row];
    }
    [self saveContext];
}

//delete all the rows for specified Entity
- (void) deleteAllRecordsInEntity:(NSString *)entityName
{
    NSFetchRequest *fetchRequest = [self getFetchRequestForPredicate:nil entity:entityName];
    [self deleteWithFetchReq:fetchRequest];
}

- (void) deleteObj:(NSString *)entityName
        managedObj: (NSManagedObject *) managedObj
{
    //NSFetchRequest *fetchRequest = [self getFetchRequestForPredicate:nil entity:entityName];
    //NSError *error = nil;
    //NSArray *arr = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
   
    [self.managedObjectContext deleteObject:managedObj];
    [self saveContext];
}

- (NSManagedObject *) getEntity:(NSString *)entityName
                     columnName:(NSString *)columnName
                          value:(NSObject*) value
{
    NSFetchRequest *fetchRequest = [self getFetchRequestForPredicate:[NSPredicate predicateWithFormat: @"%K==%@", columnName,value] entity:entityName];
    return [self executeAndReturnOne:fetchRequest];
}

- (NSManagedObject *) getEntity:(NSString *)entityName
                     withPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *fetchRequest;
    fetchRequest = [self getFetchRequestForPredicate:predicate entity:entityName];
    
    return [self executeAndReturnOne:fetchRequest];
}

//Delete entity of given entity name with columnname and value
- (void) deleteEntity:(NSString *)entityName
           columnName:(NSString *)columnName
                value:(NSString *)value
{
    NSFetchRequest *fetchRequest = [self getFetchRequestForPredicate:[NSPredicate predicateWithFormat:@"%K==%@",columnName, value] entity:entityName];
    [self deleteWithFetchReq:fetchRequest];
}


- (NSManagedObjectContext *)getManagedContext
{
    return self.managedObjectContext;
}
@end
