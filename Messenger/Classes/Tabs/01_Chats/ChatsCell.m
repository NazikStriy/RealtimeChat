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

#import "ChatsCell.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface ChatsCell()

@property (strong, nonatomic) IBOutlet UIImageView *imageUser;
@property (strong, nonatomic) IBOutlet UILabel *labelInitials;

@property (strong, nonatomic) IBOutlet UILabel *labelDescription;
@property (strong, nonatomic) IBOutlet UILabel *labelLastMessage;

@property (strong, nonatomic) IBOutlet UIImageView *imageMuted;

@property (strong, nonatomic) IBOutlet UILabel *labelElapsed;
@property (strong, nonatomic) IBOutlet UILabel *labelCounter;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation ChatsCell

@synthesize imageUser, labelInitials;
@synthesize labelDescription, labelLastMessage;
@synthesize imageMuted;
@synthesize labelElapsed, labelCounter;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)bindData:(DBRecent *)dbrecent
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	labelDescription.text = dbrecent.description;
	labelLastMessage.text = dbrecent.lastMessage;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	imageMuted.hidden = (dbrecent.mutedUntil < [[NSDate date] timestamp]);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelElapsed.text = TimeElapsed(dbrecent.lastMessageDate);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelCounter.text = (dbrecent.counter != 0) ? [NSString stringWithFormat:@"%ld new", (long) dbrecent.counter] : nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadImage:(DBRecent *)dbrecent tableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	imageUser.layer.cornerRadius = imageUser.frame.size.width/2;
	imageUser.layer.masksToBounds = YES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *path = [DownloadManager pathImage:dbrecent.picture];
	if (path == nil)
	{
		imageUser.image = [UIImage imageNamed:@"chats_blank"];
		labelInitials.text = dbrecent.initials;
		[self downloadImage:dbrecent tableView:tableView indexPath:indexPath];
	}
	else
	{
		imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
		labelInitials.text = nil;
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)downloadImage:(DBRecent *)dbrecent tableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[DownloadManager image:dbrecent.picture completion:^(NSString *path, NSError *error, BOOL network)
	{
		if ((error == nil) && ([tableView.indexPathsForVisibleRows containsObject:indexPath]))
		{
			ChatsCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			cell.imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
			cell.labelInitials.text = nil;
		}
		else if (error.code == 102)
		{
			dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
			dispatch_after(time, dispatch_get_main_queue(), ^{
				[self downloadImage:dbrecent tableView:tableView indexPath:indexPath];
			});
		}
	}];
}

@end
