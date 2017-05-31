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

#import "AllMediaView.h"
#import "AllMediaCell.h"
#import "PictureView.h"
#import "VideoView.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface AllMediaView()
{
	NSString *groupId;
	NSMutableArray *dbmessages_media;
}

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation AllMediaView

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWith:(NSString *)groupId_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	groupId = groupId_;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	self.title = @"All Media";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.collectionView registerNib:[UINib nibWithNibName:@"AllMediaCell" bundle:nil] forCellWithReuseIdentifier:@"AllMediaCell"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dbmessages_media = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadMedia];
}

#pragma mark - Load methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadMedia
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupId == %@ AND isDeleted == NO", groupId];
	RLMResults *dbmessages = [[DBMessage objectsWithPredicate:predicate] sortedResultsUsingProperty:FMESSAGE_CREATEDAT ascending:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBMessage *dbmessage in dbmessages)
	{
		if (([dbmessage.type isEqualToString:MESSAGE_PICTURE]) || ([dbmessage.type isEqualToString:MESSAGE_VIDEO]))
		{
			[dbmessages_media addObject:dbmessage];
		}
	}
}

#pragma mark - User actions

#pragma mark - UICollectionViewDataSource

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return 1;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [dbmessages_media count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AllMediaCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AllMediaCell" forIndexPath:indexPath];
	[cell bindData:dbmessages_media[indexPath.item]];
	return cell;
}

#pragma mark - UICollectionViewDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[collectionView deselectItemAtIndexPath:indexPath animated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	DBMessage *dbmessage = dbmessages_media[indexPath.item];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([dbmessage.type isEqualToString:MESSAGE_PICTURE])
	{
		[self showPicture:dbmessage];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([dbmessage.type isEqualToString:MESSAGE_VIDEO])
	{
		[self showVideo:dbmessage];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)showPicture:(DBMessage *)dbmessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *path = [DownloadManager pathImage:dbmessage.picture];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (path != nil)
	{
		PictureView *pictureView = [[PictureView alloc] initWith:dbmessage.objectId groupId:groupId];
		[self presentViewController:pictureView animated:YES completion:nil];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)showVideo:(DBMessage *)dbmessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *path = [DownloadManager pathVideo:dbmessage.video];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (path != nil)
	{
		NSURL *url = [NSURL fileURLWithPath:path];
		VideoView *videoView = [[VideoView alloc] initWith:url];
		[self presentViewController:videoView animated:YES completion:nil];
	}
}

@end
