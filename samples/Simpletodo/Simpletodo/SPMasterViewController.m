//
//  SPMasterViewController.m
//  Simpletodo
//
//  Created by Michael Johnston on 12-02-15.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import "SPMasterViewController.h"
#import "SPDetailViewController.h"
#import "SPAppDelegate.h"
#import "Todo.h"
#import "BusinessState.h"

@interface SPMasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation SPMasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)save
{
    // Save the context.
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.detailViewController = (SPDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    // Set up the edit and add buttons.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    // You can edit a todo item by tapping it when the table view is in editing mode
    [self.tableView setAllowsSelectionDuringEditing:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self save];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.tableView isEditing]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            NSManagedObject *selectedObject = [[self fetchedResultsController] objectAtIndexPath:indexPath];
            self.detailViewController.detailItem = (Todo *)selectedObject;    
        }
        [self performSegueWithIdentifier:@"showDetail" sender:self];
    } else {
        Todo *todo = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        // Flip the done flag to the opposite of whatever it is now
        todo.done = [NSNumber numberWithBool:![todo.done boolValue]];
        
        // Fade away the blue selection
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self save];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *selectedObject = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem: (Todo *)selectedObject];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    // Set up the fetched results controller.
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Todo" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    /*
	     Replace this implementation with code to handle the error appropriately.

	     abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	     */
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return __fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Todo *todo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = todo.title;
    
    // If we're in editing mode, show a discolosure arrow so you can change the text for the todo item
    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;

    // Put a checkmark next to the item if it has been marked done
    if ([todo.done boolValue])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)insertNewObject
{
    // 插入业务状态数据
    BusinessState *state = [NSEntityDescription insertNewObjectForEntityForName:@"BusinessState" inManagedObjectContext:self.fetchedResultsController.managedObjectContext];
    state.code = @5;
    state.company_id = @"99e16a3c35354857bd31a6300cbe7576";
    state.name = @"继续跟进";
    state.isopen = @1;
    state.update_time = @"2015-01-25 14:51:06";
    state.identifier = @"0363f10ad2614c188054478a057afff7";
    
    //
    BusinessState *state1 = [NSEntityDescription insertNewObjectForEntityForName:@"BusinessState" inManagedObjectContext:self.fetchedResultsController.managedObjectContext];
    state1.code = @7;
    state1.company_id = @"99e16a3c35354857bd31a6300cbe7576";
    state1.name = @"丢单";
    state1.isopen = @1;
    state1.update_time = @"2015-01-25 14:51:06";
    state1.identifier = @"266b6f349d304b26a8e6431dd3e6e168";
    
    //
    BusinessState *state2 = [NSEntityDescription insertNewObjectForEntityForName:@"BusinessState" inManagedObjectContext:self.fetchedResultsController.managedObjectContext];
    state2.code = @4;
    state2.company_id = @"99e16a3c35354857bd31a6300cbe7576";
    state2.name = @"正式报价";
    state2.isopen = @1;
    state2.update_time = @"2015-01-25 14:51:06";
    state2.identifier = @"3f1bd7517170472fb1a2aeeeadd991f4";
    
    //
    BusinessState *state3 = [NSEntityDescription insertNewObjectForEntityForName:@"BusinessState" inManagedObjectContext:self.fetchedResultsController.managedObjectContext];
    state3.code = @6;
    state3.company_id = @"99e16a3c35354857bd31a6300cbe7576";
    state3.name = @"成交";
    state3.isopen = @1;
    state3.update_time = @"2015-01-25 14:51:06";
    state3.identifier = @"54fb1a3dd6c44a9195800a5dccb7fc20";
    
    //
    BusinessState *state4 = [NSEntityDescription insertNewObjectForEntityForName:@"BusinessState" inManagedObjectContext:self.fetchedResultsController.managedObjectContext];
    state4.code = @2;
    state4.company_id = @"99e16a3c35354857bd31a6300cbe7576";
    state4.name = @"初步反馈";
    state4.isopen = @1;
    state4.update_time = @"2015-01-25 14:51:06";
    state4.identifier = @"7f14d38d2e304f1887b6e0c493c85fb4";
    
    //
    BusinessState *state5 = [NSEntityDescription insertNewObjectForEntityForName:@"BusinessState" inManagedObjectContext:self.fetchedResultsController.managedObjectContext];
    state5.code = @1;
    state5.company_id = @"99e16a3c35354857bd31a6300cbe7576";
    state5.name = @"初步沟通";
    state5.isopen = @1;
    state5.update_time = @"2015-01-25 14:51:06";
    state5.identifier = @"85f1f699220c41009f4b250840b8d400";
    
    //
    BusinessState *state6 = [NSEntityDescription insertNewObjectForEntityForName:@"BusinessState" inManagedObjectContext:self.fetchedResultsController.managedObjectContext];
    state6.code = @8;
    state6.company_id = @"99e16a3c35354857bd31a6300cbe7576";
    state6.name = @"售后";
    state6.isopen = @1;
    state6.update_time = @"2015-01-25 14:51:06";
    state6.identifier = @"90a094cf982146199b1e3987dc63fe78";
    
    //
    BusinessState *state7 = [NSEntityDescription insertNewObjectForEntityForName:@"BusinessState" inManagedObjectContext:self.fetchedResultsController.managedObjectContext];
    state7.code = @3;
    state7.company_id = @"99e16a3c35354857bd31a6300cbe7576";
    state7.name = @"见面拜访";
    state7.isopen = @1;
    state7.update_time = @"2015-01-25 14:51:06";
    state7.identifier = @"b4dbcf93881f4e82bd00f74f79179646";
    
    if ([self.fetchedResultsController.managedObjectContext hasChanges]) {
        [self.fetchedResultsController.managedObjectContext save:nil];
    }
    
    return;
    // Create a new instance of the entity managed by the fetched results controller.
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    
    // The Xcode template creates an NSManagedObject here, but in a real app it's typical to create an instance
    // of your object class (in this case Todo)
    Todo *todo = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    todo.title = @"";
    todo.done = [NSNumber numberWithBool:NO];
    NSInteger numRows = [self tableView:self.tableView numberOfRowsInSection:0];
    todo.order = @(numRows);
    
    [self save];

    // Select the row. This also ensure the segue will configure the new view with the selected item.
    [self.tableView selectRowAtIndexPath:[self.fetchedResultsController indexPathForObject:todo] animated:NO scrollPosition: UITableViewScrollPositionNone];

    [self performSegueWithIdentifier:@"showDetail" sender:self];
}

@end
