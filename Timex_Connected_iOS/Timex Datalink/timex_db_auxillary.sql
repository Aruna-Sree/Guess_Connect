DROP TABLE IF EXISTS `ActivityData`;
CREATE TABLE ActivityData (rowID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ActivityDate DOUBLE NOT NULL, ActivitySteps INTEGER NOT NULL, ActivityDistance INTEGER NOT NULL, ActivityCalories INTEGER NOT NULL, WorkoutID INTEGER, LapID INTEGER, FOREIGN KEY (WorkoutID) REFERENCES Workouts (rowID),  FOREIGN KEY (LapID) REFERENCES WorkoutLaps (rowID));