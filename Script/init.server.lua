local LunarisScript = require(script.LunarisScript)

local Script = [[
class Person {
	init(Name, Age) {
		this.Name = Name;
		this.Age = Age;
		this.Money = 0;
	}
	
	Print() {
		print("\nName: " + this.Name + "\nAge: " + this.Age + "\nMoney: " + this.Money);
	}
}

class Worker < Person {
	Work(Hours) {
		this.Money = this.Money + (Hours * 15);
	}
}

var MaccasWorker = Worker("Jamarcus", 22);

MaccasWorker.Print();

MaccasWorker.Work(8);

MaccasWorker.Print();
]]

LunarisScript:Run(Script)