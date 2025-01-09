using EnumSets
using Test

function fuzz(ESet)
    E = eltype(ESet)
    es = instances(E)
    n = length(es)
    for e in es
        @test e === only(ESet((e,)))
    end
    for _ in 1:100
        n1 = rand(0:n)
        n2 = rand(0:n)
        s1 = ESet(rand(es, n1))
        s2 = ESet(rand(es, n2))
        # no hash collisions
        @test (hash(s1) == hash(s2)) === (s1 === s2)
        ss = [ESet(rand(es, n2)) for _ in 1:rand(1:4)]
        @test length(s1) === length(Set(s1)) <= n1
        @test length(s1) === count(Returns(true), s1)
        @test (s1 ⊆ s2) === (Set(s1) ⊆ Set(s2))
        @test (s1 ⊊ s2) === (Set(s1) ⊊ Set(s2))
        @test push(s1, s2...) === s1 ∪ s2

        @test (s1 ∩ s2) === ESet(Set(s1) ∩ Set(s2))
        @test (s1 ∪ s2) === ESet(Set(s1) ∪ Set(s2))
        @test setdiff(s1, s2) === ESet(setdiff(Set(s1), Set(s2)))
        @test symdiff(s1, s2) === ESet(symdiff(Set(s1), Set(s2)))

        @test ∩(ss...) === ESet(∩(Set.(ss)...))
        @test ∪(ss...) === ESet(∪(Set.(ss)...))
        @test setdiff(ss...) === ESet(setdiff(Set.(ss)...))
        @test symdiff(ss...) === ESet(symdiff(Set.(ss)...))
        e = rand(es)
        @test (e in s1) === (e in Set(s1))

        @test (s1 ∩ s2) === filter(in(s1), s2)
    end
end

@testset "simple enum" begin
    @enum Alphabet begin
        A=1 
        B=2 
        C=3
    end
    ASet = enumsettype(Alphabet)

    s = ASet()
    @test typeof(s) === ASet
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

    @testset setdiff(ASet((A,B)), ASet((B,C))) === ASet((A,))

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

    fuzz(ASet)
end

@testset "hash eq" begin
    @enum English Hello World
    @enum Spanish Hola Mundo
    EnglishSet = enumsettype(English)
    SpanishSet = enumsettype(Spanish)
    @test hash(EnglishSet((Hello,))) != hash(EnglishSet((World,)))
    @test hash(EnglishSet((Hello,))) != hash(Hello)
    @test hash(SpanishSet((Hola,))) != hash(EnglishSet((Hello,)))
    @test EnglishSet((Hello,)) != SpanishSet((Hola,))
    @test !isequal(EnglishSet((Hello,)), SpanishSet((Hola,)))
    @test isequal(EnglishSet((Hello,)), EnglishSet((Hello,)))
    @test ==(EnglishSet((Hello,)), EnglishSet((Hello,)))
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

    fuzz(NegativeSet)
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

const ProgrammerExcuseSet = enumsettype(ProgrammerExcuse)

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
    fuzz(ProgrammerExcuseSet)
    @test_throws "Enum ProgrammerExcuse does not fit into carrier type UInt64." enumsettype(ProgrammerExcuse; carrier=UInt64)
end


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

@testset "exhaustive enums" begin
    @enum X1 X1_1 X1_2 X1_3 X1_4 X1_5 X1_6 X1_7 X1_8
    @enum X2 X2_1 X2_2 X2_3 X2_4 X2_5 X2_6 X2_7 X2_8 X2_9 X2_10 X2_11 X2_12 X2_13 X2_14 X2_15 X2_16
    @enum X4 X4_1 X4_2 X4_3 X4_4 X4_5 X4_6 X4_7 X4_8 X4_9 X4_10 X4_11 X4_12 X4_13 X4_14 X4_15 X4_16 X4_17 X4_18 X4_19 X4_20 X4_21 X4_22 X4_23 X4_24 X4_25 X4_26 X4_27 X4_28 X4_29 X4_30 X4_31 X4_32
    @enum X8 X8_1 X8_2 X8_3 X8_4 X8_5 X8_6 X8_7 X8_8 X8_9 X8_10 X8_11 X8_12 X8_13 X8_14 X8_15 X8_16 X8_17 X8_18 X8_19 X8_20 X8_21 X8_22 X8_23 X8_24 X8_25 X8_26 X8_27 X8_28 X8_29 X8_30 X8_31 X8_32 X8_33 X8_34 X8_35 X8_36 X8_37 X8_38 X8_39 X8_40 X8_41 X8_42 X8_43 X8_44 X8_45 X8_46 X8_47 X8_48 X8_49 X8_50 X8_51 X8_52 X8_53 X8_54 X8_55 X8_56 X8_57 X8_58 X8_59 X8_60 X8_61 X8_62 X8_63 X8_64
    @enum X16 X16_1 X16_2 X16_3 X16_4 X16_5 X16_6 X16_7 X16_8 X16_9 X16_10 X16_11 X16_12 X16_13 X16_14 X16_15 X16_16 X16_17 X16_18 X16_19 X16_20 X16_21 X16_22 X16_23 X16_24 X16_25 X16_26 X16_27 X16_28 X16_29 X16_30 X16_31 X16_32 X16_33 X16_34 X16_35 X16_36 X16_37 X16_38 X16_39 X16_40 X16_41 X16_42 X16_43 X16_44 X16_45 X16_46 X16_47 X16_48 X16_49 X16_50 X16_51 X16_52 X16_53 X16_54 X16_55 X16_56 X16_57 X16_58 X16_59 X16_60 X16_61 X16_62 X16_63 X16_64 X16_65 X16_66 X16_67 X16_68 X16_69 X16_70 X16_71 X16_72 X16_73 X16_74 X16_75 X16_76 X16_77 X16_78 X16_79 X16_80 X16_81 X16_82 X16_83 X16_84 X16_85 X16_86 X16_87 X16_88 X16_89 X16_90 X16_91 X16_92 X16_93 X16_94 X16_95 X16_96 X16_97 X16_98 X16_99 X16_100 X16_101 X16_102 X16_103 X16_104 X16_105 X16_106 X16_107 X16_108 X16_109 X16_110 X16_111 X16_112 X16_113 X16_114 X16_115 X16_116 X16_117 X16_118 X16_119 X16_120 X16_121 X16_122 X16_123 X16_124 X16_125 X16_126 X16_127 X16_128

    @test length(instances(X1)) == 1*8
    @test length(instances(X2)) == 2*8
    @test length(instances(X4)) == 4*8
    @test length(instances(X8)) == 8*8
    @test length(instances(X16)) == 16*8

    SetX1 = enumsettype(X1)
    SetX2 = enumsettype(X2)
    SetX4 = enumsettype(X4)
    SetX8 = enumsettype(X8)
    SetX16 = enumsettype(X16)

    @test sizeof(SetX1) == 1
    @test sizeof(SetX2) == 2
    @test sizeof(SetX4) == 4
    @test sizeof(SetX8) == 8
    @test sizeof(SetX16) == 16

    @test EnumSets.PackingTrait(SetX1()) == EnumSets.OffsetBasedPacking{0}()
    @test EnumSets.PackingTrait(SetX2()) == EnumSets.OffsetBasedPacking{0}()
    @test EnumSets.PackingTrait(SetX4()) == EnumSets.OffsetBasedPacking{0}()
    @test EnumSets.PackingTrait(SetX8()) == EnumSets.OffsetBasedPacking{0}()
    @test EnumSets.PackingTrait(SetX16()) == EnumSets.OffsetBasedPacking{0}()

    fuzz(SetX1)
    fuzz(SetX2)
    fuzz(SetX4)
    fuzz(SetX8)
    fuzz(SetX16)
end

@testset "redefine" begin
    @enum Alphabet A B C
    S = enumsettype(Alphabet)
    ab = S((A, B))
    @enum Alphabet A B C D
    @test S === enumsettype(Alphabet)
    @test ab === S((A, B))
    @test push(ab, D) == S((A, B, D))
end
