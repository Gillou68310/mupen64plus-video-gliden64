if [ ! -d "GLideN64" ]; then
    echo
    echo "GLideN64"
    git clone "https://github.com/Gillou68310/GLideN64.git"
    cd "GLideN64"
    git remote rename origin github
    git config user.name "Gillou68310"
    git config user.email "gilles.siberlin@outlook.com"
    cd ..
fi

cd "GLideN64"

DIFF=`git diff`
if [ "$DIFF" != "" ]; then
    echo
    echo "GLideN64 directory is not clean.  Please commit, stash, or reset your changes."
    cd ..
    continue
fi

REMOTE=`git remote`
if [ ! `echo "$REMOTE" | grep "github"` ]; then
    echo
    echo "Adding github remote for GLideN64."
    git remote add github "https://github.com/Gillou68310/GLideN64.git"
fi

REMOTE=`git remote`
if [ ! `echo "$REMOTE" | grep "upstream"` ]; then
    echo
    echo "Adding upstream remote for GLideN64."
    git remote add upstream "https://github.com/gonetz/GLideN64.git"
fi

echo "Syncing GLideN64"
git fetch upstream
git checkout master
git merge upstream/master
git push github master

cd src
./getRevision.sh