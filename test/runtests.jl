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
        @test length(s1) === length(Set(s1)) <= n1
        @test length(s1) === count(Returns(true), s1)
        @test (s1 ⊆ s2) === (Set(s1) ⊆ Set(s2))
        @test (s1 ⊊ s2) === (Set(s1) ⊊ Set(s2))
        @test push(s1, s2...) === s1 ∪ s2

        @test (s1 ∩ s2) === ESet(Set(s1) ∩ Set(s2))
        @test (s1 ∪ s2) === ESet(Set(s1) ∪ Set(s2))
        @test symdiff(s1, s2) === ESet(symdiff(Set(s1), Set(s2)))

        @test ∩(ss...) === ESet(∩(Set.(ss)...))
        @test ∪(ss...) === ESet(∪(Set.(ss)...))
        @test symdiff(ss...) === ESet(symdiff(Set.(ss)...))
        e = rand(es)
        @test (e in s1) === (e in Set(s1))
    end
end

@enum X x1 x2 x3 x4 x5 x6 x7 x8
@enumset SetX <: EnumSet{X, UInt8}

@testset "Packed into a single byte" begin
    @test EnumSets.PackingTrait(SetX((x1,))) === EnumSets.OffsetBasedPacking{0}()
    @test sizeof(SetX) == 1

    @test only(SetX((x1,))) === x1
    @test only(SetX((x2,))) === x2
    @test only(SetX((x3,))) === x3
    @test only(SetX((x4,))) === x4
    @test only(SetX((x5,))) === x5
    @test only(SetX((x6,))) === x6
    @test only(SetX((x7,))) === x7
    @test only(SetX((x8,))) === x8

    fuzz_booleans(SetX)
end

@enum Alphabet begin
    A=1 
    B=2 
    C=3
end
@enumset ASet <: EnumSet{Alphabet}

@testset "simple enum" begin

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

    @test union(ASet([A]), [B], (B,)) === ASet((A, B))

    @test intersect(ASet([A,B]), ASet([C,B])) === ASet([B])

    # iteration
    s = ASet((A,C))
    next = iterate(s)
    @test !isnothing(next)
    a, state = next
    @test a === A

    next = iterate(s, state)
    @test !isnothing(next)
    c, state = next
    @test c === C

    next = iterate(s, state)
    @test isnothing(next)

    fuzz_booleans(ASet)
end

@enum Negative::Int128 begin
    a=1
    b=-1
    c=typemin(Int128)
    d=typemax(Int128)
end
@enumset NegativeSet <: EnumSet{Negative}

@testset "negative enum" begin

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
@enumset ProgrammerExcuseSet <: EnumSet{ProgrammerExcuse}

@testset "big enum" begin
    @test length(instances(ProgrammerExcuse)) > 64
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

@test_throws "Enum ProgrammerExcuse does not fit into carrier type UInt64." enumsettype(ProgrammerExcuse; carrier=UInt64)

@testset "blsr" begin
    for T in [UInt8, UInt16, UInt32, UInt64, UInt128]
        @test iszero(EnumSets.blsr(zero(T)))
        for _ in 1:100
            x = rand(T)
            iszero(x) && continue
            i = Base.trailing_zeros(x)
            @test x === EnumSets.blsr(x) + one(T) << i
        end
    end
end
