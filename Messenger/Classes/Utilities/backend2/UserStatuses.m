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
@interface UserStatuses()
{
	FIRDatabaseReference *firebase;
}
@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation UserStatuses

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (UserStatuses *)shared
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	static dispatch_once_t once;
	static UserStatuses *userStatuses;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_once(&once, ^{ userStatuses = [[UserStatuses alloc] init]; });
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return userStatuses;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)init
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[NotificationCenter addObserver:self selector:@selector(initObservers) name:NOTIFICATION_APP_STARTED];
	[NotificationCenter addObserver:self selector:@selector(initObservers) name:NOTIFICATION_USER_LOGGED_IN];
	[NotificationCenter addObserver:self selector:@selector(actionCleanup) name:NOTIFICATION_USER_LOGGED_OUT];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

#pragma mark - Backend methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)initObservers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([FUser currentId] != nil)
	{
		if (firebase == nil) [self createObservers];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)createObservers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	firebase = [[FIRDatabase database] referenceWithPath:FUSERSTATUS_PATH];
	[firebase observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		if (snapshot.exists)
		{
			for (NSDictionary *userStatus in [snapshot.value allValues])
			{
				dispatch_async(dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL), ^{
					[self updateRealm:userStatus];
				});
			}
		}
		else [self initUserStatuses];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateRealm:(NSDictionary *)userStatus
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	[DBUserStatus createOrUpdateInRealm:realm withValue:userStatus];
	[realm commitWriteTransaction];
}

#pragma mark - Cleanup methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCleanup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[firebase removeAllObservers]; firebase = nil;
}

#pragma mark - Initialization methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)initUserStatuses
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self initUserStatus:@"Available"];
	[self initUserStatus:@"Busy"];
	[self initUserStatus:@"At school"];
	[self initUserStatus:@"At the movies"];
	[self initUserStatus:@"At work"];
	[self initUserStatus:@"Battery about to die"];
	[self initUserStatus:@"Can't talk now"];
	[self initUserStatus:@"In a meeting"];
	[self initUserStatus:@"At the gym"];
	[self initUserStatus:@"Sleeping"];
	[self initUserStatus:@"Urgent calls only"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self actionCleanup];
	[self createObservers];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)initUserStatus:(NSString *)name
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *object = [FObject objectWithPath:FUSERSTATUS_PATH];
	object[FUSERSTATUS_NAME] = name;
	[object saveInBackground:^(NSError *error)
	{
		if (error != nil) NSLog(@"initUserStatus error: %@", error);
	}];
}

@end
