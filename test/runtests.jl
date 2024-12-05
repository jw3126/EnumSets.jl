using EnumSets
using Test

function fuzz_booleans(ESet)
    E = eltype(ESet)
    es = instances(E)
    n = length(es)
    for _ in 1:100
        n1 = rand(0:n)
        n2 = rand(0:n)
        s1 = ESet(rand(es, n1))
        s2 = ESet(rand(es, n2))
        ss = [ESet(rand(es, n2)) for _ in 1:rand(1:4)]
        @test length(s1) == length(Set(s1)) <= n1
        @test (s1 ⊆ s2) == (Set(s1) ⊆ Set(s2))
        @test (s1 ⊊ s2) == (Set(s1) ⊊ Set(s2))

        @test Set(s1 ∩ s2) == Set(s1) ∩ Set(s2)
        @test Set(s1 ∪ s2) == Set(s1) ∪ Set(s2)
        @test Set(symdiff(s1, s2)) == symdiff(Set(s1), Set(s2))

        @test Set(∩(ss...)) == ∩(Set.(ss)...)
        @test Set(∪(ss...)) == ∪(Set.(ss)...)
        @test Set(symdiff(ss...)) == symdiff(Set.(ss)...)
        e = rand(es)
        @test (e in s1) === (e in Set(s1))
    end
end

@enum Alphabet begin
    A=1 
    B=2 
    C=3
end

@testset "simple enum" begin
    @enumset ASet <: EnumSet{Alphabet}

    s = ASet()
    @test isbitstype(ASet)
    @test isempty(s)
    @test length(s) == 0
    sA = push(s, A)
    @test length(sA) == 1
    @test A in sA
    @test !(B in sA)
    @test !(C in sA)
    @test sA === push(sA, A)

    sAC = push(sA, C)
    @test A in sAC
    @test !(B in sAC)
    @test (C in sAC)
    @test collect(sAC) == [A, C]

    @test ASet([A,B]) != ASet([B])
    @test ASet([A,B]) === ASet([B, A])
    @test union(ASet([A]), ASet([B])) == ASet([A, B])
    @test union(ASet([A]), ASet([B]), ASet([A,B])) == ASet([A, B])

    @test intersect(ASet([A,B]), ASet([C,B])) === ASet([B])

    fuzz_booleans(ASet)
end

@enum Negative::Int128 begin
    a=1
    b=-1
    c=typemin(Int128)
    d=typemax(Int128)
end

@testset "negative enum" begin
    @enumset NegativeSet <: EnumSet{Negative}

    @test NegativeSet((a,b, d)) != NegativeSet((a,))
    @test NegativeSet((a,b, d)) ⊆ NegativeSet((a,b, c, d))
    @test NegativeSet((a,b, d)) ⊊ NegativeSet((a,b, c, d))
    @test !(NegativeSet((a,b, d)) ⊊ NegativeSet((a,b, d)))
    @test NegativeSet((a,b)) ⊈ NegativeSet((a, c, d))

    fuzz_booleans(NegativeSet)
end

@enum ProgrammerExcuse begin
    WorksOnMyMachine
    MercurialRetrograde
    CosmicRayBitFlip
    CoffeeNotFound
    KeyboardNotErgonomic
    WrongMoonPhase
    CatOnKeyboard
    StandupMeetingTooLong
    BadrouterIonization
    CompilerFeelingMoody
    CacheTooCachey
    NotEnoughEmojis
    TooManyEmojis
    QuotaExceededForSighs
    WifiPasswordTooStrong
    DnsLookingOtherWay
    FirewallTooFirey
    CloudsTooFluffy
    GitBranchTooBranchy
    StackOverflowDown
    RedditWasDistracting
    SlackNotSlacking
    ZoomBackgroundTooVirtual
    MousepadTooSlippery
    ChairNotGaming
    DeskTooClean
    DeskTooMessy
    MonitorNotVertical
    SecondMonitorJealous
    ThirdMonitorMissing
    RubberDuckOnVacation
    TerminalTooColourful
    FontNotCoding
    TabsVsSpacesDispute
    GitConflictTooConflicting
    LinuxKernelTooKernelly
    WindowsUpdateConspiracy
    MacBookTooShiny
    DockerWhaleNotSwimming
    KubernetesPodsHomesick
    JiraTicketEscaped
    BacklogTooLogged
    SprintTooMarathon
    ScrumTooChaotic
    WaterfallTooWet
    AgileNotNimble
    TechnicalDebtCollector
    LegacyCodeHaunting
    UnitTestsTooUnity
    IntegrationTestsDancing
    E2ETestsDaydreaming
    CICDPipelineClogged
    DevOpsSleeping
    ProdEnvAngry
    StagingStaged
    TestEnvTesting
    LocalhostLost
    PortsAllBusy
    MemoryLeakingSlowly
    CPUOnStrike
    GPUMining
    RAMDownloading
    SSLCertificateShy
    APITooRESTful
    GraphQLTooGraphy
    WebsocketDisconnected
end

@testset "big enum" begin
    @test length(instances(ProgrammerExcuse)) > 64
    @enumset ProgrammerExcuseSet <: EnumSet{ProgrammerExcuse}
    @test 8*sizeof(ProgrammerExcuseSet) >= length(instances(ProgrammerExcuse))
    s = ProgrammerExcuseSet()
    @test isempty(s)
    @test length(s) == 0
    for (i,e) in enumerate(instances(ProgrammerExcuse))
        @test !(e in s)
        s = push(s, e)
        @test e in s
        @test length(s) == i
        @test collect(s) == collect(instances(ProgrammerExcuse))[1:i]
    end

    fuzz_booleans(ProgrammerExcuseSet)
end
