package FlashVideo::Site::Playserial;

use strict;
use FlashVideo::Utils;
use URI;
use FlashVideo::URLFinder;
use URI::Escape qw(uri_unescape);
use HTML::Entities qw(decode_entities);

our $VERSION = '0.00';
sub Version() { $VERSION; }


sub find_video {

my ($self,  $browser, $embed_url, $prefs) = @_;

  my @urls;

  for my $iframe($browser->content =~ /<iframe[^>]+src=["']?([^"'>]+)/gi) {
    $iframe = decode_entities($iframe);
    $iframe = URI->new_abs($iframe, $browser->uri);
    debug "Found iframe: $iframe";
    next if ($iframe =~ m%http://www\.facebook\.com/plugins/like\.php%);
    next if ($iframe =~ m%http://www.hellspy.cz%);
    next if ($iframe =~ m%http://rutube.ru%);
    if ($iframe =~  m%^.*file=(http://.*\.mp4)&.*$%) {
       my $actual_url = $1;
       debug "Found URL $actual_url";
       push @urls, $actual_url;
       next;
    }
    my $sub_browser = $browser->clone;
    $sub_browser->get($iframe);
    # Recurse!
    my($package, $possible_url) = FlashVideo::URLFinder->find_package($iframe, $sub_browser);

    # Before fetching the url, give the package a chance
    if($package->can("pre_find")) {
      $package->pre_find($sub_browser);
    }

    info "Downloading $iframe";
    $sub_browser->get($iframe);

    my($actual_url, @suggested_fnames) = eval {
      $package->find_video($sub_browser, $possible_url, $prefs);
    };
    push @urls, $actual_url if $actual_url;
  }

  my $count = 0;
  for my $url (@urls) {
     info "URL found = ".$url."[".$count."]";
     $count++;
  }
  # Selection to be done...
  # Proper file name needed...
  return ( $urls[0], "test.mp4");

}

1;
