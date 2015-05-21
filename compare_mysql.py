#!/usr/bin/python
#
#
# (c) 2015 Vladimir Smolensky <arizal@gmail.com> under the GPL
#     http://www.gnu.org/licenses/gpl.html
#  
# Compare all databases/tables in 2 mysql servers
# the script compares the row counts for each database/table on the first server with the second
# the servers are expected to have same databases - async repl or galera for example
# The purpose is to check if the replication is in sync
#

import MySQLdb
import prettyprint

dbs = { 'db1': {
	'host': '',
	'user': 'comp',
	'password': '',
	'conn': None,
	'cur': None
	},
	'db2': {
	'host': '',
	'user': 'comp',
	'password': '',
	'conn': None,
	'cur':None
	}
	}

for i,db in dbs.iteritems():
	print db['host']
	db['conn']=MySQLdb.connect(host=db['host'], 
			user=db['user'],
			passwd=db['password']
			)
	db['cur']=db['conn'].cursor()


c1=dbs['db1']['cur']
c2=dbs['db2']['cur']

c1.execute("SHOW DATABASES")
databases=c1.fetchall()
err=0
ok=0
for row in databases:
	if row[0] == 'information_schema' or row[0] == 'performance_schema':
		continue
	c1.execute("USE %s" % row[0])
	c2.execute("USE %s" % row[0])
	c1.execute("SHOW TABLES")
	tables=c1.fetchall()
	#tables = [['stats_daily']]
	for table in tables:
		# SELECT TABLE_ROWS FROM information_schema.tables WHERE TABLE_SCHEMA = 'my_db_name' AND TABLE_NAME = 'my_table_name';

		c1.execute("SELECT count(*) from %s" % table[0])
		c2.execute("SELECT count(*) from %s" % table[0])
		a=c1.fetchone()[0]
		b=c2.fetchone()[0]
		if a != b:
			print "Database %s table %s db1: %s - db2: %s ERROR" % (row[0], table[0], a, b)
			err+=1
		else:
			print "Database %s table %s %d-%d OK" % (row[0], table[0], a, b)
			ok+=1

print "Results: %d ok, %d errors" % (ok, err)
