#!/bin/bash
# Checks instruction.md for the facts the task needs and for things it must not say.
cd "$(dirname "$0")"
f=instruction.md
[ -f "$f" ] || { echo "Missing $f. Write it next to this script."; exit 1; }

problems=0
need() { grep -qiE "$1" "$f" || { echo "MISSING: $2"; problems=$((problems+1)); }; }
avoid() { grep -qiE "$1" "$f" && { echo "REMOVE:  $2"; problems=$((problems+1)); }; }

need 'removeImages\(' "the API code block from part 2"
need 'forKeysMatching predicate: @escaping @Sendable \(String\) -> Bool' "the exact predicate parameter"
need ') async' "the async version"
need 'completionHandler' "the completion handler version"
need 'forKey' "that the predicate gets the key passed as forKey"
need 'processor' "that a match removes every processor variant"
need '@' "that keys can contain @"
need 'fromMemory' "fromMemory"
need 'fromDisk' "fromDisk"
need 'relaunch|new ImageCache|another ImageCache|same (name|folder)' "removal from a new ImageCache on the same folder"
need 'diskStorage' "that files stored straight into diskStorage are left alone"
need 'extra files|other files|no (new )?files|hidden' "no extra files in the cache folder"
need 'expired|size limit' "that normal cleaning must keep working"
need 'once' "that the completion handler runs once"
need 'callbackQueue' "callbackQueue"
need 'again' "that a removed key can be stored again"
need 'iOS 15|minimum' "the minimum OS versions"
need 'dependenc' "no new dependencies"

avoid 'solve\.sh|solution/' "the solution folder or solve.sh"
avoid 'xattr|extended attribute' "an implementation hint"
avoid 'XCTest|test\.sh|RemoveMatchingTests|regression' "a description of how it is checked"
avoid 'simulator' "the Simulator (this task has none)"
avoid '/Users/|/workspace|/logs' "absolute paths"
grep -q $'\r' "$f" && { echo "REMOVE:  Windows (CRLF) line endings"; problems=$((problems+1)); }

[ "$problems" -eq 0 ] && echo "Looks good." || echo "$problems thing(s) to fix."
