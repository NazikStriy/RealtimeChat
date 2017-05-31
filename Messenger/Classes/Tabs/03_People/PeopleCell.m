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

#import "PeopleCell.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface PeopleCell()

@property (strong, nonatomic) IBOutlet UIImageView *imageUser;
@property (strong, nonatomic) IBOutlet UILabel *labelInitials;

@property (strong, nonatomic) IBOutlet UILabel *labelName1;
@property (strong, nonatomic) IBOutlet UILabel *labelName2;
@property (strong, nonatomic) IBOutlet UILabel *labelStatus;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation PeopleCell

@synthesize imageUser, labelInitials;
@synthesize labelName1, labelName2, labelStatus;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)bindData:(DBContact *)dbcontact
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	labelName1.text = dbcontact.fullname;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelName2.text = nil;
	labelStatus.text = nil;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	imageUser.layer.cornerRadius = imageUser.frame.size.width/2;
	imageUser.layer.masksToBounds = YES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	imageUser.image = [UIImage imageNamed:@"people_blank"];
	labelInitials.text = [dbcontact initials];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)bindData:(DBContact *)dbcontact dbuser:(DBUser *)dbuser
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	labelName1.text = nil;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelName2.text = dbcontact.fullname;
	labelStatus.text = dbuser.status;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadImage:(DBUser *)dbuser tableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	imageUser.layer.cornerRadius = imageUser.frame.size.width/2;
	imageUser.layer.masksToBounds = YES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *path = [DownloadManager pathImage:dbuser.picture];
	if (path == nil)
	{
		imageUser.image = [UIImage imageNamed:@"people_blank"];
		labelInitials.text = [dbuser initials];
		[self downloadImage:dbuser tableView:tableView indexPath:indexPath];
	}
	else
	{
		imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
		labelInitials.text = nil;
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)downloadImage:(DBUser *)dbuser tableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[DownloadManager image:dbuser.picture completion:^(NSString *path, NSError *error, BOOL network)
	{
		if ((error == nil) && ([tableView.indexPathsForVisibleRows containsObject:indexPath]))
		{
			PeopleCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			cell.imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
			cell.labelInitials.text = nil;
		}
		else if (error.code == 102)
		{
			dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
			dispatch_after(time, dispatch_get_main_queue(), ^{
				[self downloadImage:dbuser tableView:tableView indexPath:indexPath];
			});
		}
	}];
}

@end
