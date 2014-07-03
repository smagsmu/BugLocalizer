# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

package Bugzilla::Extension::BugLocalizer;
use strict;

use constant NAME => 'BugLocalizer';

use constant REQUIRED_MODULES => [
    {
       package => 'XML-Writer',
        module  => 'XML::Writer',
        version =>  0.625,
    },
#    {
#       package => 'Git-Repository',
#        module  => 'Git::Repository',
#        version => 1.311,
#    },
];

use constant OPTIONAL_MODULES => [
];

__PACKAGE__->NAME;
