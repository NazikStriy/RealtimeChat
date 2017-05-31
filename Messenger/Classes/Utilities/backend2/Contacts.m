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

#import "utilities.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface Contacts()
{
	NSTimer *timer;
	BOOL refreshUserInterface;
}
@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation Contacts

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (Contacts *)shared
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	static dispatch_once_t once;
	static Contacts *contacts;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_once(&once, ^{ contacts = [[Contacts alloc] init]; });
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return contacts;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)init
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[NotificationCenter addObserver:self selector:@selector(requestAccess) name:NOTIFICATION_APP_STARTED];
	[NotificationCenter addObserver:self selector:@selector(requestAccess) name:NOTIFICATION_USER_LOGGED_IN];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	timer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(refreshUserInterface) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

#pragma mark - Contacts methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)requestAccess
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	CNContactStore *store = [[CNContactStore alloc] init];
	[store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *error)
	{
		if (granted)
		{
			[self loadContacts:store];
		}
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadContacts:(CNContactStore *)store
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSMutableArray *identifiers = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSArray *keys = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey];
	NSPredicate *predicate = [CNContact predicateForContactsInContainerWithIdentifier:store.defaultContainerIdentifier];
	NSArray *cncontacts = [store unifiedContactsMatchingPredicate:predicate keysToFetch:keys error:nil];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (CNContact *cncontact in cncontacts)
	{
		[self loadContact:cncontact];
		[identifiers addObject:cncontact.identifier];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBContact *dbcontact in [DBContact allObjects])
	{
		if ([identifiers containsObject:dbcontact.identifier] == NO)
		{
			[self deleteContact:dbcontact];
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	refreshUserInterface = YES;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadContact:(CNContact *)cncontact
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSMutableDictionary *contact = [[NSMutableDictionary alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	contact[@"identifier"] = cncontact.identifier;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	contact[@"firstname"] = cncontact.givenName;
	contact[@"lastname"] = cncontact.familyName;
	contact[@"fullname"] = [NSString stringWithFormat:@"%@ %@", cncontact.givenName, cncontact.familyName];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSMutableArray *numbers = [[NSMutableArray alloc] init];
	for (CNLabeledValue *labeledValue in cncontact.phoneNumbers)
	{
		[numbers addObject:[labeledValue.value valueForKey:@"digits"]];
	}
	contact[@"numbers"] = numbers;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	contact[@"isDeleted"] = @NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_async(dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL), ^{
		[self updateRealm:contact];
	});
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateRealm:(NSDictionary *)contact
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:contact];
	temp[@"numbers"] = [contact[@"numbers"] componentsJoinedByString:@","];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	[DBContact createOrUpdateInRealm:realm withValue:temp];
	[realm commitWriteTransaction];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)deleteContact:(DBContact *)dbcontact
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	dbcontact.isDeleted = YES;
	[realm commitWriteTransaction];
}

#pragma mark - Notification methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshUserInterface
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (refreshUserInterface)
	{
		[NotificationCenter post:NOTIFICATION_REFRESH_CONTACTS];
		refreshUserInterface = NO;
	}
}

@end
