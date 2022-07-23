#!/bin/sh

if [ "`git status -s`" ]
then
    echo "The working directory is dirty. Please commit any pending changes."
    exit 1;
fi

echo "--- Deleting old publication"
rm -rf build

echo "--- Checking out gh-pages branch into dist"
#git worktree add -B gh-pages build origin/gh-pages
git worktree add build gh-pages

echo "--- Removing existing files"
rm -rf build/*
mv build/.git /tmp/meuastral_git

echo "--- Generating site"
elm-app build
mv /tmp/meuastral_git build/.git

echo "--- Updating gh-pages branch"
cd build &&
  git add --all &&
  git commit -m "Publishing to gh-pages (publish.sh)" &&
  git push origin gh-pages

git worktree remove build
cd ..
