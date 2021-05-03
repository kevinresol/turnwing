package;

import tink.unit.*;
import tink.testrunner.*;

class RunTests {
	static function main() {
		Runner.run(TestBatch.make([new JsonTest(), new FluentTest(), new ExtendedFluentTest()])).handle(Runner.exit);
	}
}
