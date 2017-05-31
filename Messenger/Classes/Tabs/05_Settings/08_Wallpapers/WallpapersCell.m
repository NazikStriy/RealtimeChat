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

#import "WallpapersCell.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface WallpapersCell()

@property (strong, nonatomic) IBOutlet UIImageView *imageItem;
@property (strong, nonatomic) IBOutlet UIImageView *imageSelected;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation WallpapersCell

@synthesize imageItem, imageSelected;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)bindData:(NSString *)path
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	imageItem.image = [UIImage imageNamed:path];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	BOOL selected = [[FUser wallpaper] isEqualToString:path];
	imageSelected.hidden = (selected == NO);
}

@end
