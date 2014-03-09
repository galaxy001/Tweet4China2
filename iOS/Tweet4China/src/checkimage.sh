# code from StackOverflow.com
# http://stackoverflow.com/questions/8087997/automatic-resizing-for-non-retina-image-versions
# by nschum http://stackoverflow.com/users/168939/nschum
#
#!/bin/bash
# Downsamples all retina ...@2x.png images.

echo "Downsampling retina images..."

dir='../images'
find "$dir" -name "*@2x.png" | while read image; do

    imageName=${image:10:${#image}-17}
    grep "$imageName" * -R > /dev/zero
    if [ $? != 0 ]; then
        mv ../images/${imageName}@2x.png ~/tmp/removed_images/
    fi

done
