#!/bin/bash
# Simple rollback test

# 1. Add a small staged change
echo "rollback test" >> test.txt
git add test.txt

# 2. FORCE a failure inside deploy.sh
rm -rf releases  # this breaks packaging every time

# 3. Run deploy.sh (which will now fail → rollback)
./deploy.sh
