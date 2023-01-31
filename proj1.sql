-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst ASC, namelast ASC
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear 
  ORDER BY birthyear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, avgheight, count
  FROM q1iii
  WHERE avgheight > 70
  ORDER BY birthyear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT p.namefirst, p.namelast, p.playerID, h.yearid
  FROM people p, halloffame h
  WHERE (p.playerID = h.playerID) and (h.inducted = 'Y')
  ORDER BY h.yearid DESC,  p.playerID
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT q.namefirst, q.namelast, q.playerID, c.schoolID, q.yearid
  FROM q2i q, collegeplaying c, schools s
  WHERE s.schoolState = 'CA' 
    AND c.playerid = q.playerID
    AND c.schoolID = s.schoolID
  ORDER BY q.yearid DESC, c.schoolID, q.playerID
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT q2i.playerID, q2i.namefirst, q2i.namelast, c.schoolID 
  FROM q2i LEFT JOIN collegeplaying c 
    ON q2i.playerID = c.playerid
  ORDER BY q2i.playerID DESC, c.schoolID 
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT pp.playerID, pp.namefirst, pp.namelast, bat.yearID, 
    (bat.H + bat.H2B + 2*bat.H3B + 3*bat.HR + 0.0) / (bat.AB + 0.0) AS slg
  FROM people pp LEFT OUTER JOIN batting bat
    ON pp.playerID = bat.playerID
  WHERE bat.AB > 50
  ORDER BY slg DESC, bat.yearID ASC, pp.playerID ASC
  LIMIT 10 
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  WITH lifetimeslg(playerID, total) AS
  (
    SELECT playerID, (SUM(H) + SUM(H2B) + 2*SUM(H3B) + 3*SUM(HR) + 0.0) / (SUM(AB) + 0.0) AS total
    FROM batting
    GROUP BY playerID
    HAVING SUM(AB) > 50
  )
  SELECT pp.playerID, pp.namefirst, pp.namelast, lf.total
  FROM people pp INNER JOIN lifetimeslg lf
  ON pp.playerID = lf.playerID
  ORDER BY lf.total DESC, pp.playerID
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  WITH lifetimeslg(playerID, total) AS
  (
    SELECT playerID, (SUM(H) + SUM(H2B) + 2*SUM(H3B) + 3*SUM(HR) + 0.0) / (SUM(AB) + 0.0) AS total
    FROM batting
    GROUP BY playerID
    HAVING SUM(AB) > 50
  )
  SELECT pp.namefirst, pp.namelast, lf.total
  FROM people pp 
    INNER JOIN lifetimeslg lf
    ON pp.playerID = lf.playerID
  WHERE lf.total > (
    SELECT total
    FROM lifetimeslg
    WHERE playerID = "mayswi01"
  )
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearID, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries 
  GROUP BY yearID
  ORDER BY yearID
;

-- Question 4ii
-- reference source: https://popsql.com/sql-templates/analytics/how-to-create-histograms-in-sql
CREATE VIEW q4ii(binid, low, high, count)
AS
  -- SELECT CAST ((salary/3400000) AS INT) as binid, 
  -- MIN(salary) as low, MAX(salary) as high, COUNT(*) as count
  -- FROM salaries
  -- WHERE yearID = 2016
  -- GROUP BY 1
  -- ORDER BY 1

  WITH bin_boundaries AS (
    SELECT 
      MIN(salary) AS min_salary, 
      MAX(salary) AS max_salary, 
      CAST((MAX(salary) - MIN(salary))/ 10 AS INT) AS bin_width
    FROM salaries
    WHERE yearID == 2016
  ), bins AS (
    SELECT 
      min_salary + (bin_width * binid) AS low_boundary, 
      min_salary + (bin_width * (binid+1)) AS high_boundary, 
      binid
    FROM bin_boundaries, binids
  )
  SELECT binid, low_boundary, high_boundary, 
    (CASE WHEN binid < 9 THEN 0 ELSE 1 END) + COUNT(*)
  FROM salaries, bins
  WHERE salary >= low_boundary AND salary < high_boundary AND yearID == 2016
  GROUP BY binid
  ORDER BY binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  WITH yearlySalaries AS (
    SELECT yearID, MIN(salary) AS minsalary, MAX(salary) AS maxsalary, AVG(salary) AS avgsalary
    FROM salaries
    GROUP BY yearID
  )
  SELECT curr.yearID, curr.minsalary - prev.minsalary AS mindiff, curr.maxsalary - prev.maxsalary AS maxdiff, curr.avgsalary - prev.avgsalary AS avgdiff
  FROM yearlySalaries curr 
  INNER JOIN yearlySalaries prev 
    ON curr.yearID = prev.yearID + 1
  WHERE curr.yearID != (SELECT MIN(yearID) FROM salaries)
  ORDER BY curr.yearID
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT pp.playerID, pp.nameFirst, pp.nameLast, MAX(sa.salary), sa.yearID
  FROM people pp JOIN salaries sa ON pp.playerID = sa.playerID
  WHERE yearID in (2000, 2001)
  GROUP BY sa.yearID
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  WITH allStarSalaries AS (
    SELECT allstar.playerID, allstar.teamID, sa.salary
    FROM allstarfull allstar 
    JOIN salaries sa ON allstar.playerID = sa.playerID
    WHERE allstar.yearID = 2016 AND sa.yearID = 2016
  )
    SELECT teamID, (MAX(salary) - MIN(salary)) as diffAvg
    FROM allStarSalaries allstar
    GROUP BY teamID
;

