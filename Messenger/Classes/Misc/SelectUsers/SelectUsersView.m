//
// Copyright (c) 2016 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "SelectUsersView.h"
#import "SelectUsersCell1.h"
#import "SelectUsersCell2.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface SelectUsersView()
{
	NSArray *blockerIds;
	NSMutableArray *numbers;

	RLMResults *dbusers;
	RLMResults *dbgroups;

	NSMutableArray *selection1;
	NSMutableArray *selection2;
}

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation SelectUsersView

@synthesize delegate;
@synthesize searchBar;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	self.title = @"Select Users";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
																						  action:@selector(actionCancel)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
																						  action:@selector(actionDone)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView registerNib:[UINib nibWithNibName:@"SelectUsersCell1" bundle:nil] forCellReuseIdentifier:@"SelectUsersCell1"];
	[self.tableView registerNib:[UINib nibWithNibName:@"SelectUsersCell2" bundle:nil] forCellReuseIdentifier:@"SelectUsersCell2"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, CGFLOAT_MIN)];
	self.tableView.tableFooterView = [[UIView alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	blockerIds = [Blocked blockerIds];
	numbers = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	selection1 = [[NSMutableArray alloc] init];
	selection2 = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadContacts];
	[self loadGroups];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewWillDisappear:animated];
	[self dismissKeyboard];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)dismissKeyboard
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.view endEditing:YES];
}

#pragma mark - Realm methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadContacts
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[numbers removeAllObjects];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isDeleted == NO"];
	RLMResults *dbcontacts = [DBContact objectsWithPredicate:predicate];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBContact *dbcontact in dbcontacts)
	{
		for (NSString *number in [dbcontact.numbers componentsSeparatedByString:@","])
			[numbers addObject:number];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadUsers];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadUsers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *text = searchBar.text;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *format = @"objectId != %@ AND NOT objectId IN %@ AND phone IN %@ AND fullname CONTAINS[c] %@";
	NSPredicate *predicate = [NSPredicate predicateWithFormat:format, [FUser currentId], blockerIds, numbers, text];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dbusers = [[DBUser objectsWithPredicate:predicate] sortedResultsUsingProperty:FUSER_FULLNAME ascending:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView reloadData];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadGroups
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *text = searchBar.text;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *format = @"members CONTAINS[c] %@ AND isDeleted == NO AND name CONTAINS[c] %@";
	NSPredicate *predicate = [NSPredicate predicateWithFormat:format, [FUser currentId], text];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dbgroups = [[DBGroup objectsWithPredicate:predicate] sortedResultsUsingProperty:FGROUP_NAME ascending:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView reloadData];
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCancel
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDone
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (([selection1 count] == 0) && ([selection2 count] == 0)) { [ProgressHUD showError:@"Please select some users or groups."]; return; }
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSMutableArray *users = [[NSMutableArray alloc] init];
	NSMutableArray *groups = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBUser *dbuser in dbusers)
	{
		if ([selection1 containsObject:dbuser.objectId])
			[users addObject:dbuser];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBGroup *dbgroup in dbgroups)
	{
		if ([selection2 containsObject:dbgroup.objectId])
			[groups addObject:dbgroup];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self dismissViewControllerAnimated:YES completion:^{
		if (delegate != nil) [delegate didSelectUsers:users groups:groups];
	}];
}

#pragma mark - UIScrollViewDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissKeyboard];
}

#pragma mark - Table view data source

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return 2;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (section == 0) return [dbusers count];
	if (section == 1) return [dbgroups count];
	return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (indexPath.section == 0)
	{
		SelectUsersCell1 *cell = [tableView dequeueReusableCellWithIdentifier:@"SelectUsersCell1" forIndexPath:indexPath];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		DBUser *dbuser = dbusers[indexPath.row];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[cell bindData:dbuser];
		[cell loadImage:dbuser tableView:tableView indexPath:indexPath];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		cell.accessoryType = [selection1 containsObject:dbuser.objectId] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		//-----------------------------------------------------------------------------------------------------------------------------------------
		return cell;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (indexPath.section == 1)
	{
		SelectUsersCell2 *cell = [tableView dequeueReusableCellWithIdentifier:@"SelectUsersCell2" forIndexPath:indexPath];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		DBGroup *dbgroup = dbgroups[indexPath.row];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[cell bindData:dbgroup];
		[cell loadImage:dbgroup tableView:tableView indexPath:indexPath];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		cell.accessoryType = [selection2 containsObject:dbgroup.objectId] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		//-----------------------------------------------------------------------------------------------------------------------------------------
		return cell;
	}
	return nil;
}

#pragma mark - Table view delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (indexPath.section == 0)
	{
		DBUser *dbuser = dbusers[indexPath.row];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if ([selection1 containsObject:dbuser.objectId])
			[selection1 removeObject:dbuser.objectId];
		else [selection1 addObject:dbuser.objectId];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		cell.accessoryType = [selection1 containsObject:dbuser.objectId] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (indexPath.section == 1)
	{
		DBGroup *dbgroup = dbgroups[indexPath.row];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if ([selection2 containsObject:dbgroup.objectId])
			[selection2 removeObject:dbgroup.objectId];
		else [selection2 addObject:dbgroup.objectId];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		cell.accessoryType = [selection2 containsObject:dbgroup.objectId] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	}
}

#pragma mark - UISearchBarDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self loadUsers];
	[self loadGroups];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar setShowsCancelButton:YES animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar setShowsCancelButton:NO animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	searchBar.text = @"";
	[searchBar resignFirstResponder];
	[self loadUsers];
	[self loadGroups];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar resignFirstResponder];
}

@end
