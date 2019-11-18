module metrics::categories::duplication

import IO;
import String;
import Set;
import List;
import Map;
import util::Math;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import aliases;
import metrics::utility;
import utility;


set[tuple[loc, loc]] findDuplicates(Files files) {
	map[tuple[loc, str], str] lineHashes = calculateLineHashes(files);
	return calculateDuplicatedBlocks(lineHashes);
}

int calculateDuplicationPercentage() {
	return 0;
}

map[tuple[loc, str], str] calculateLineHashes(map[loc locations, list[str] _] files) {
	map[tuple[loc, str], str] linesHashes = ();

	for (loc location <- files.locations) {
		list[str] lines = files[location];
		
		int offset = 0;
		int lineIndex = 1;
		for (str line <- lines) {
			if (isBlank(line) || isComment(line)) {
				offset += size(line) + 2;
				lineIndex += 1;
				continue;
			}
		
			lineLocation = location(0, 0, <0, 0>, <0, 0>);
			lineLocation.offset = offset;
			lineLocation.length = size(line) + 1;
			lineLocation.end.line = lineIndex;
			lineLocation.begin.line = lineIndex;
			lineLocation.end.column = lineLocation.length;
			lineLocation.begin.column = 0;
			
			line = trim(line);
			key = <lineLocation, line>;
			md5Hash = hashMD5(line);
			
			linesHashes[key] = md5Hash;
			
			offset += lineLocation.length + 1;
			lineIndex += 1;
		}
	}
	
	return linesHashes;
}

set[tuple[loc, loc]] calculateDuplicatedBlocks(map[tuple[loc, str] lines, str _] lineHashes) {
	set[tuple[loc, loc]] duplicatedBlocksLocation = {};
	buckets = invert(lineHashes);
	
	for (bucket <- buckets) {
		set[tuple[loc location, str content]] linesInBucket = buckets[bucket];
		
		while(size(linesInBucket) > 1) {
			tuple[tuple[loc, str] line, set[tuple[loc, str]] matches] takeOne = takeOneFrom(linesInBucket);
			tuple[loc location, str content] currentLine = takeOne.line;
			linesInBucket = takeOne.matches;
			
			for (tuple[loc location, str content] match <- linesInBucket) {
				// Check if the content is the same
				if (match.content != currentLine.content) continue;
				
				// Get all duplicated lines previous and posterior
				tuple[loc block1Loc, loc block2Loc, list[str] block]  matchedPrevious = matchConsecutive(true, currentLine, match, lineHashes.lines);
				tuple[loc block1Loc, loc block2Loc, list[str] block]  matchedPosterior = matchConsecutive(false, currentLine, match, lineHashes.lines);
				
				// Check duplicated block size is greater or equal to 6
				list[str] block = matchedPrevious.block + currentLine.content + matchedPosterior.block;
				if (size(block) < 6) continue;
				
				//  Add duplicated blocks location to set of duplicates
				loc blockLocation1 = constructBlockLocation(matchedPrevious.block1Loc, matchedPosterior.block1Loc, currentLine.location);
				loc blockLocation2 = constructBlockLocation(matchedPrevious.block2Loc, matchedPosterior.block2Loc, match.location);
				if (!(<blockLocation2, blockLocation1> in duplicatedBlocksLocation)) {
					duplicatedBlocksLocation = duplicatedBlocksLocation + <blockLocation1, blockLocation2>;
				}
			}
		}
	}
	
	return duplicatedBlocksLocation;
}

loc constructBlockLocation(loc locationPrevious, loc locationPosterior, loc locationCurrent) {
	locationPrevious.length = locationPrevious.length + locationPosterior.length - locationCurrent.length;
	locationPrevious.end.line = locationPosterior.end.line;
	locationPrevious.end.column = locationPosterior.end.column;
	
	return locationPrevious;
}

tuple[loc, loc, list[str]] matchConsecutive(bool matchingPrevious, tuple[loc location, str line] currentLine, tuple[loc location, str line] match, set[tuple[loc, str]] hashedLines) {
	loc locationCurrent = currentLine.location;
	loc locationMatch = match.location;
	list[str] block = [];
	
	while (locationCurrent.begin.line > 0) {
		// Find consecutives of both blocks
		tuple[loc location, str line] consecutive1 = findConsecutive(matchingPrevious, locationCurrent, hashedLines);
		tuple[loc location, str line] consecutive2 = findConsecutive(matchingPrevious, locationMatch, hashedLines);
		
		// If there is no consecutive line or the lines do not match, done
		if (consecutive1.line == "" || consecutive2.line == "") break;
		if (consecutive1.line != consecutive2.line) break;
	
		// Update blocks location and block content
		locationCurrent = constructLocation(matchingPrevious, locationCurrent, consecutive1.location);
		locationMatch = constructLocation(matchingPrevious, locationMatch, consecutive2.location);
		block = constructBlock(matchingPrevious, block, consecutive1.line);
	}
	
	return <locationCurrent, locationMatch, block>;
}

tuple[loc, str] findConsecutive(bool matchingPrevious, loc currentLoc, set[tuple[loc, str]] hashedLines) {
	str path = currentLoc.path;
	str file = currentLoc.file;
	
	// If it is matching previous line, lineIndex = currentLoc.begin.line - 1
	int lineIndex;
	if (matchingPrevious) lineIndex = currentLoc.begin.line - 1;
	else lineIndex = currentLoc.end.line + 1;
	
	// Find consecutive line
	for (tuple[loc location, str _] line <- hashedLines) {
		loc lineLoc = line.location;
		if (lineLoc.path != path) continue;
		if (lineLoc.file != file) continue;
		if (lineLoc.begin.line == lineIndex) return line;
	}
	
	return <currentLoc, "">;
}

loc constructLocation(bool matchingPrevious, loc current, loc consecutive) {
	loc first;
	loc last;
	
	if (matchingPrevious) {
		first = consecutive;
		last = current;
	} else {
		first = current;
		last = consecutive;
	}
	
	first.length = first.length + last.length;
	first.end.line = last.end.line;
	first.end.column = last.end.column;
	
	return first;
}

list[str] constructBlock(bool matchingPrevious, list[str] current, str consecutive) {
	if (matchingPrevious) return consecutive + current;
	return current + consecutive;
}
