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

@implementation DBContact

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (NSString *)primaryKey
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return @"identifier";
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)initials
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (([self.firstname length] != 0) && ([self.lastname length] == 0)) return [self.firstname substringToIndex:1];
	if (([self.firstname length] == 0) && ([self.lastname length] != 0)) return [self.lastname substringToIndex:1];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (([self.firstname length] != 0) && ([self.lastname length] != 0))
		return [NSString stringWithFormat:@"%@%@", [self.firstname substringToIndex:1], [self.lastname substringToIndex:1]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return nil;
}

@end
