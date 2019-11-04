module model

import IO;
import Set;
import List;
import Map;
import Type;
import util::Math;
import tests::stats;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import calculation::helpers;
import calculation::categories::volume;
import scoring::ranks;
import scoring::categories::duplication;
import scoring::categories::unitcomplexity;
import scoring::categories::unitsize;
import scoring::categories::volume;


// list[Declaration] smallsql = retrieveAst(|project://smallsql0.21_src|);
// list[Declaration] hsqldb = retrieveAst(|project://hsqldb-2.3.1|);

tuple[int, Rank] calculatVolumeMetric(list[Declaration] ast) {
	int volume = calculateVolume(ast);
	Rank rank = calculateVolumeRank(volume);
	return <volume, rank>;
}

void calculate(list[Declaration] ast) {
	println("Volume Rank: <calculatVolumeMetric(ast)>");
}
