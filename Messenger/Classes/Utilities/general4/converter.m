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
NSString* Date2Short(NSDate *date)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSString* Date2Medium(NSDate *date)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSString* Date2MediumTime(NSDate *date)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
}

#pragma mark -

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSString* TimeElapsed(long long timestamp)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *elapsed;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSDate *date = [NSDate dateWithTimestamp:timestamp];
	NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:date];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (seconds < 60)
	{
		elapsed = @"Just now";
	}
	else if (seconds < 60 * 60)
	{
		int minutes = (int) (seconds / 60);
		elapsed = [NSString stringWithFormat:@"%d %@", minutes, (minutes > 1) ? @"mins" : @"min"];
	}
	else if (seconds < 24 * 60 * 60)
	{
		int hours = (int) (seconds / (60 * 60));
		elapsed = [NSString stringWithFormat:@"%d %@", hours, (hours > 1) ? @"hours" : @"hour"];
	}
	else if (seconds < 7 * 24 * 60 * 60)
	{
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"EEEE"];
		elapsed = [formatter stringFromDate:date];
	}
	else elapsed = Date2Short(date);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return elapsed;
}
