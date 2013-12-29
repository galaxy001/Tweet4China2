#!/usr/bin/python

import commands

cn_lines = []
for line in commands.getoutput('''grep "_(@" src/* -R''').splitlines():
  line = line[line.index("_(@")+3: line.index(")")]
  if len(line) > 3:
    cn_lines.append(line)

distincted_lines = []
for cn in cn_lines:
  found = False
  for dis in distincted_lines:
    if dis == cn:
      found = True
  if not found:
    distincted_lines.append(cn)

old_str = file("Tweet4China/zh-Hant.lproj/Localizable.strings").read()

for dis in distincted_lines:
  if not old_str.count(dis):
    print '%s = %s' % (dis, '""')

