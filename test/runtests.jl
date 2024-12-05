using EnumSets
using Test

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
end
