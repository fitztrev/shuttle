#!/bin/sh

echo '---\nlayout: none\n---\n' | cat - index.html > temp && mv temp index.html
