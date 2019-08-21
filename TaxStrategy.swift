import Foundation

let taxBracket: [(start: Double, end: Double, rate: Double, baseTax: Double)] = [(0, 9700, 0.1, 0), (9701, 39475, 0.12, 970), (39476, 84200, 0.22, 4543), (84201, 160725, 0.24, 14382.5), (160726, 204100, 0.32, 32748.5), (204101, 510300, 0.35, 46628.5), (510301, Double.greatestFiniteMagnitude, 0.37, 153798)]

func retireBalanceOn(currentBalance: Double, annualContrib: Double, ciRate: Double, years: Double) -> Double {
    //detailed calculation can be found here: http://www.moneychimp.com/articles/finworks/fmbasinv.htm
    return currentBalance * pow(1 + ciRate, years) + annualContrib * ((pow(1 + ciRate, years + 1) - (1 + ciRate)) / ciRate)
}

func taxOn(grossPay: Double) -> Double {
    for bracket in taxBracket {
        if grossPay > bracket.start && grossPay < bracket.end {
            return bracket.baseTax + bracket.rate * (grossPay - bracket.start)
        }
    }
    return 0
}

func contributionAmount(salary: Double, regPercent: Double, rothPercent: Double) -> (reg: Double, roth: Double) {
    let companyMatch = min(5000, salary * (regPercent + rothPercent) * 0.5)
    let regAmount = salary * regPercent + companyMatch
    var rothAmount = salary * rothPercent
    
    let rothHigh = salary - regAmount
    let rothLow = (salary - regAmount) - salary * rothPercent
    for bracket in taxBracket {
        if bracket.end > rothLow && bracket.start < rothHigh {
             rothAmount -= (min(bracket.end, rothHigh) - max(bracket.start, rothLow)) * bracket.rate
        }
    }
    return (regAmount, rothAmount)
}

func validateContribution(salary: Double, regPercent: Double, rothPercent: Double) -> Bool {
    let maximumYearlyContrib: Double = 19000
    let totalContrib = salary * (regPercent + rothPercent)
    return totalContrib < maximumYearlyContrib
}

func testRetrieval(principle: Double, years: Double, rate: Double, annualRetrieval: Double) {
    var balance = principle
    for i in 0...Int(years) {
        print(i, Int(balance))
        balance -= annualRetrieval
        balance *= 1 + rate
    }
}

func retrievelAmount(principle: Double, years: Double, rate: Double) -> Double {
    //This calculation is derived from the "compound interest rate with annual contribution formula" by 1.Substitue annual contribution with annual retrieval and 2. Calculate the final balance using Geometric Progression 3. Set the balance to 0 and calculate the annual retrival amount. It has been tested by the function testRetrival.
    let subZ = 1 + rate
    let subA = pow(subZ, years) * (subZ - 1) / (pow(subZ, years) - subZ)
    return principle * subA / (1 + subA)
}

func growWithoutAnnualContribution(principle: Double, years: Double, rate: Double) -> Double{
    return principle * pow(1 + rate, years)
}

func combinedAnnualTakehomeRetrieval(salary: Double, regPercent: Double, rothPercent: Double, yearsToGrow: Double, yearsOfRetirement: Double,  ciRate: Double, yearsNotContributing: Double) -> Int {
    let contrib = contributionAmount(salary: salary, regPercent: regPercent, rothPercent: rothPercent)
    var regRetireBalance = retireBalanceOn(currentBalance: 0, annualContrib: contrib.reg, ciRate: ciRate, years: yearsToGrow)
    var rothRetireBalance = retireBalanceOn(currentBalance: 0, annualContrib: contrib.roth, ciRate: ciRate, years: yearsToGrow)
    regRetireBalance = growWithoutAnnualContribution(principle: regRetireBalance, years: yearsNotContributing, rate: ciRate)
    rothRetireBalance = growWithoutAnnualContribution(principle: rothRetireBalance, years: yearsNotContributing, rate: ciRate)
    print("regBalance", Int(regRetireBalance))
    print("rothBalance", Int(rothRetireBalance))
    let regRetrivalAmt = retrievelAmount(principle: regRetireBalance, years: yearsOfRetirement, rate: ciRate)
    let rothRetrivalAmt = retrievelAmount(principle: rothRetireBalance, years: yearsOfRetirement, rate: ciRate)
    let regTakeHome = regRetrivalAmt - taxOn(grossPay: regRetrivalAmt)
    let totalTakeHome = Int(rothRetrivalAmt + regTakeHome)
    
    print("reg retrieve: ", Int(regRetrivalAmt))
    print("Roth retrieve: ", Int(rothRetrivalAmt))
    print("reg takehome: ", Int(regTakeHome))
    print("total takehome: ", Int(totalTakeHome))
    return totalTakeHome
}

let annualCompoundInterestRate = 0.12 //12 percent annual rate of return.
let annualSalary: Double = 90000
let yearsContributing: Double = 40
let yearsOfRetirement: Double = 20
let yearsNotContributing: Double = 0

func optimalAlloc(for intPercent: Int) {
    print("Results for different Percentage allocation to Roth 401k vs Regular 401k.")
    var takeHomeArray = [Int]()
    for i in 0...intPercent {
        let regPercent = Double(i) / 100
        let rothPercent = Double(intPercent - i) / 100
        print("\nReg Contrib Percent: ", regPercent, "Roth Contrib Percent: ", rothPercent)
        takeHomeArray.append(combinedAnnualTakehomeRetrieval(salary: annualSalary, regPercent: regPercent, rothPercent: rothPercent, yearsToGrow: yearsContributing, yearsOfRetirement: yearsOfRetirement, ciRate: annualCompoundInterestRate, yearsNotContributing: yearsNotContributing))
    }
    let info = takeHomeArray.enumerated().max { (a, b) -> Bool in
        a.element < b.element
    }
    if let info = info {
        print("\nOptimal Strategy ->\nPercent of Regular 401k:", info.offset, "%. Percent of Roth 401k:", intPercent - info.offset, "%. Annual Retirement Takehome =", info.element)
    }
}

optimalAlloc(for: 16) //optimal allocation for %16 of your salary invested into regular 401k and Roth 401k.

//In conclusion, if you're an aggressive investor like I am, go ALL-IN for the Roth 401k! Because in 40 years, your 401k balance will be somewhere in the range of 10-20 million dollars which will put your average tax rate close to the tax rate in the highest tax bracket(extremely high compared to your income tax rate right now which is the rate you will be taxed for the Roth 401k)! Plus the tax rate is almost guaranteed to go up because of the tremendous amount of debt the nation is in right now. To get a high yield close to 12%(the rate of return for S&P 500 for the past 10 years, generally known as "the stock market"), I highly recommend building an investment portfolio comprised of growth STOCK mutal funds. The art of picking mutual funds is beyond the scope of this program, but as a wise investor, you should always understand what you are getting into.
