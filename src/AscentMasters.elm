module AscentMasters exposing
    ( CosmicRay
    , archangel_image
    , archangel_name
    , archangel_name_for
    , color_name
    , for_birthday
    , master_details
    , master_details_for
    , master_image
    , master_name
    , master_name_for
    , number
    , ray_details
    , ray_details_for
    , test_subject
    )

import Array exposing (Array)
import Date exposing (Date)
import Locale


test_subject : CosmicRay
test_subject =
    Cinco


type CosmicRay
    = Um
    | Dois
    | Tres
    | Quatro
    | Cinco
    | Seis
    | Sete


type alias CosmicRayAttributes =
    { number : String
    , colorName : String
    , masterName : String
    , masterDetails : String
    , masterImage : String
    , archangelName : String
    , archangelImage : String
    , rayDetails : String
    }


type alias CosmicRayCopy =
    { masterName : String
    , masterDetails : String
    , archangelName : String
    , rayDetails : String
    }


for_birthday : Date -> Maybe CosmicRay
for_birthday date =
    let
        sum =
            (Date.year date |> sumDigits)
                + (Date.monthNumber date |> sumDigits)
                + (Date.day date |> sumDigits)
    in
    Array.get (rayNumber sum - 1) rays


rays : Array CosmicRay
rays =
    Array.fromList [ Um, Dois, Tres, Quatro, Cinco, Seis, Sete ]


attributes : Array CosmicRayAttributes
attributes =
    Array.fromList
        [ { number = "1"
          , colorName = "blue"
          , masterName = "Mestre El Morya"
          , masterDetails = "O Mestre El Morya, no tempo do Mestre Jesus, foi Melchior, um dos três sábios dos países do Oriente. Ele foi o lendário Rei Arthur da Sagrada Taça Graal, bem como o humanista e estadista Thomas Morus, que escreveu A Utopia."
          , masterImage = "1-el-morya.png"
          , archangelName = "Miguel"
          , archangelImage = "1-arcanjo-miguel.png"
          , rayDetails = "A chama do Raio Azul Representa: Fé, Poder e Ação. As pessoas deste raio são muitas vezes fáceis de serem reconhecidas em relação às outras, em geral essas pessoas possuem ilimitada força e energia. Elas criam e constroem, possuem ação, são líderes natos."
          }
        , { number = "2"
          , colorName = "gold"
          , masterName = "Mestre Lanto"
          , masterDetails = "O Mestre Lanto em tempos passados, foi um grande governante da China e fez sua ascensão há muitos séculos. Depois conquistou o direito de assumir maiores encargos e foi assim que ele transferiu a custódia de seu Templo de Luz que fica na China, ao sul da Grande Muralha perto de Lanchow, ao seu discípulo Confúcio, que presentemente lá trabalha. No seu grande amor, o Mestre Lanto resolveu ficar por aqui para ajudar a Terra nesta época de crise."
          , masterImage = "2-lanto.png"
          , archangelName = "Jofiel"
          , archangelImage = "2-arcanjo-jofiel.png"
          , rayDetails = "A chama do Raio Dourado Representa: Sabedoria, Elevação e Iluminação. Deve-se sempre visualizar esta cor envolvendo nosso corpo quando necessitamos dos atributos que ela pode nos dar. É o raio do educador e do professor."
          }
        , { number = "3"
          , colorName = "pink"
          , masterName = "Mestra Rowena"
          , masterDetails = "A Mestra Rowena está pronta para servir a todos que a procuram. Ela estimula, mantém e protege, não só os gênios que já conseguiram alcançar o topo da escada, como também, igualmente, os humildes aspirantes que acabam de colocar os pés no primeiro degrau, em direção à meta. Ela guarda o símbolo da Liberdade. O Foco de Luz da Chama da Liberdade guardada pela Mestra Rowena situa-se no sul da França, em Chateau Liberté, no plano físico."
          , masterImage = "3-rowena.png"
          , archangelName = "Samuel"
          , archangelImage = "3-arcanjo-samuel.png"
          , rayDetails = "A chama do Raio Rosa Representa: Amor Incondicional, Adoração e Beleza. As pessoas que a ele pertencem amam a beleza em todas as formas de expressão e são amáveis e compassivas."
          }
        , { number = "4"
          , colorName = "whitesmoke"
          , masterName = "Mestre Seraphys Bey"
          , masterDetails = "O Mestre Seraphis Bay é invocado para harmonia, pureza e ascensão. Também afasta o Gênio Contrário. Sua proteção está subordinada à atual Chama da Ascensão de Luxor no Egito, que foi levada por ele e outros devotos para lá antes de submergir nas ondas do oceano, o continente de Atlântida."
          , masterImage = "4-seraphys-bey.png"
          , archangelName = "Gabriel"
          , archangelImage = "4-arcanjo-gabriel.png"
          , rayDetails = "A chama do Raio Branco Representa: Harmonia, Pureza e Ascensão. As pessoas que pertencem a este raio são, geralmente, dotadas de talento artístico com tendências para música, danças clássicas, teatro de óperas, pintura, escultura e arquitetura. Tais pessoas são quase sempre abençoadas com o poder espiritual e cheias de ânimo, além de possuírem o dom de \"penetrar e ver através das coisas\"."
          }
        , { number = "5"
          , colorName = "green"
          , masterName = "Mestre Hilarion"
          , masterDetails = "O Mestre Hilarion no tempo do Mestre Jesus foi o apóstolo Paulo. Seu santuário está no campo etéreo, situado sobre a Ilha de Creta. A chama verde é curadora, deve-se compreender que tanto pode ser a cura do físico, como também a cura da alma da humanidade."
          , masterImage = "5-hilarion.png"
          , archangelName = "Rafael"
          , archangelImage = "5-arcanjo-rafael.png"
          , rayDetails = "A chama do Raio Verde Representa: Verdade, Abundância e Cura. As pessoas que pertencem a este raio geralmente atuam nas áreas de pesquisa científica e da saúde, como médicos, enfermeiros e curandeiros."
          }
        , { number = "6"
          , colorName = "maroon"
          , masterName = "Mestra Nada"
          , masterDetails = "O Mestre Jesus foi seu diretor até pouco tempo atrás, quando juntamente com o Mestre Kuthumi, se elevaram à condição de Instrutores do Mundo. Hoje sua responsável é a Mestra Nada e juntamente com Maria de Nazaré – Mãe de Jesus, elas prestam serviços em benefício da humanidade. Seu templo de iluminação encontra-se na América do Sul. Costuma-se prestar homenagens a esta mestra do Raio Rubi, no início da Primavera, quando a natureza, aparentemente \"morta\", desperta para a vida."
          , masterImage = "6-mestra-nada.png"
          , archangelName = "Uriel"
          , archangelImage = "6-arcanjo-uriel.png"
          , rayDetails = "A chama do Raio Rubi Representa: Devoção, Cooperação e Serviços Prestados à Cura e a Paz da Humanidade. As pessoas deste raio geralmente se dedicam a servir a humanidade muitas vezes sem obter reconhecimentos dos serviços prestados, como sacerdotes, religiosos e missionários."
          }
        , { number = "7"
          , colorName = "blueviolet"
          , masterName = "Mestre Saint German"
          , masterDetails = "O Mestre Saint Germain, realizou sua ascensão no ano de 1684. É tarefa do Sétimo Raio instruir a humanidade de como conseguir por meio da Chama Violeta a libertação, transmutar seus erros, transformar-se e tudo recomeçar. É um instrumento cósmico e divino, usado pelas Ascencionadas Legiões da Luz, para libertar toda vida prisioneira. Estamos na Era de Aquário e com ela recebemos a proteção da Chama Violeta transmutadora dirigida por nosso amado Mestre Saint Germain. Seu santuário fica no monte Shasta, na Califórnia – EUA. Estamos vivendo a nossa Encarnação de Ouro, o livre arbítrio não nos foi tirado, mas agora a escolha é clara: a luz ou as trevas. Toda essa hierarquia cósmica, estes seres maravilhosos e dentre eles, os Arcanjos e Anjos, se fazem presentes como nunca, unicamente para nos libertar. Isso está acontecendo graças ao grande trabalho dos Mestres Ascencionados e de seus trabalhadores na Terra."
          , masterImage = "7-saint-germain.png"
          , archangelName = "Ezequiel"
          , archangelImage = "7-arcanjo-ezequiel.png"
          , rayDetails = "A chama do Raio Violeta representa: Transmutação, Purificação e Magnetização. As pessoas que pertencem a este raio possuem muitas aptidões e grande amor pela liberdade."
          }
        ]


englishCopies : Array CosmicRayCopy
englishCopies =
    Array.fromList
        [ { masterName = "Master El Morya"
          , masterDetails = "Master El Morya is associated with will, faith, and right action. In spiritual tradition he is remembered as a teacher of discipline, leadership, and service, helping people use strength with clarity and responsibility."
          , archangelName = "Michael"
          , rayDetails = "The Blue Ray represents faith, power, and action. People connected with this ray tend to carry strong energy, initiative, and a natural ability to lead, build, and move plans forward."
          }
        , { masterName = "Master Lanto"
          , masterDetails = "Master Lanto is connected with wisdom, learning, and illumination. His path emphasizes patience, study, discernment, and the generous use of knowledge in service to others."
          , archangelName = "Jophiel"
          , rayDetails = "The Golden Ray represents wisdom, elevation, and illumination. It is linked with teachers, students, mentors, and anyone seeking clearer understanding."
          }
        , { masterName = "Lady Master Rowena"
          , masterDetails = "Lady Master Rowena is associated with love, beauty, encouragement, and protection for those who are growing spiritually. Her ray invites compassion, refinement, and devotion to freedom."
          , archangelName = "Samuel"
          , rayDetails = "The Pink Ray represents unconditional love, adoration, and beauty. People connected with this ray often value harmony, kindness, affection, and beauty in many forms."
          }
        , { masterName = "Master Serapis Bey"
          , masterDetails = "Master Serapis Bey is invoked for harmony, purity, and ascension. His teaching points to discipline, spiritual refinement, and the effort to bring order and elevation into daily life."
          , archangelName = "Gabriel"
          , rayDetails = "The White Ray represents harmony, purity, and ascension. It is often associated with artistic sensitivity, spiritual strength, music, dance, painting, sculpture, architecture, and clear inner perception."
          }
        , { masterName = "Master Hilarion"
          , masterDetails = "Master Hilarion is associated with truth, healing, and clear investigation. In tradition he is linked with the Apostle Paul and with a spiritual sanctuary over the island of Crete."
          , archangelName = "Raphael"
          , rayDetails = "The Green Ray represents truth, abundance, and healing. People connected with this ray often feel drawn to research, science, health, medicine, nursing, and healing work."
          }
        , { masterName = "Lady Master Nada"
          , masterDetails = "Lady Master Nada is associated with devotion, service, cooperation, and compassionate work for peace and healing. Her path emphasizes humble service and care for humanity."
          , archangelName = "Uriel"
          , rayDetails = "The Ruby Ray represents devotion, cooperation, service, healing, and peace. People connected with this ray often serve others quietly, sometimes without public recognition."
          }
        , { masterName = "Master Saint Germain"
          , masterDetails = "Master Saint Germain is associated with transformation, freedom, and the Violet Flame. His teaching emphasizes renewal, purification, responsibility, and the choice to begin again with greater awareness."
          , archangelName = "Ezekiel"
          , rayDetails = "The Violet Ray represents transmutation, purification, and magnetization. People connected with this ray often have many talents and a strong love of freedom."
          }
        ]


getAttributes : CosmicRay -> Maybe CosmicRayAttributes
getAttributes r =
    Array.get (index r) attributes


getEnglishCopy : CosmicRay -> Maybe CosmicRayCopy
getEnglishCopy r =
    Array.get (index r) englishCopies


defaultAttributes : CosmicRayAttributes
defaultAttributes =
    { number = ""
    , colorName = ""
    , masterName = ""
    , masterDetails = ""
    , masterImage = ""
    , archangelName = ""
    , archangelImage = ""
    , rayDetails = ""
    }


defaultCopy : CosmicRayCopy
defaultCopy =
    { masterName = ""
    , masterDetails = ""
    , archangelName = ""
    , rayDetails = ""
    }


ptBRCopy : CosmicRay -> CosmicRayCopy
ptBRCopy ray =
    { masterName = master_name ray
    , masterDetails = master_details ray
    , archangelName = archangel_name ray
    , rayDetails = ray_details ray
    }


attributeOrDefault : (CosmicRayAttributes -> String) -> CosmicRay -> String
attributeOrDefault getter ray =
    getAttributes ray
        |> Maybe.withDefault defaultAttributes
        |> getter


localizedCopyOrDefault : Locale.Locale -> (CosmicRayCopy -> String) -> CosmicRay -> String
localizedCopyOrDefault locale getter ray =
    (case Locale.toQueryParam locale of
        "en-US" ->
            getEnglishCopy ray

        _ ->
            Just (ptBRCopy ray)
    )
        |> Maybe.withDefault defaultCopy
        |> getter


sumDigits : Int -> Int
sumDigits =
    String.fromInt
        >> String.split ""
        >> List.map (String.toInt >> Maybe.withDefault 0)
        >> List.sum


rayNumber : Int -> Int
rayNumber ds =
    if ds <= 7 then
        ds

    else if ds < 10 then
        ds - 7

    else
        ds |> sumDigits |> rayNumber


master_image : CosmicRay -> String
master_image r =
    publicAssetPath (webpPath (attributeOrDefault .masterImage r))


archangel_image : CosmicRay -> String
archangel_image r =
    publicAssetPath (webpPath (attributeOrDefault .archangelImage r))


webpPath : String -> String
webpPath path =
    if String.endsWith ".png" path then
        String.dropRight 4 path ++ ".webp"

    else
        path


publicAssetPath : String -> String
publicAssetPath path =
    if String.isEmpty path || String.startsWith "/" path then
        path

    else
        "/" ++ path


master_details : CosmicRay -> String
master_details r =
    attributeOrDefault .masterDetails r


master_details_for : Locale.Locale -> CosmicRay -> String
master_details_for locale r =
    localizedCopyOrDefault locale .masterDetails r


ray_details : CosmicRay -> String
ray_details r =
    attributeOrDefault .rayDetails r


ray_details_for : Locale.Locale -> CosmicRay -> String
ray_details_for locale r =
    localizedCopyOrDefault locale .rayDetails r


number : CosmicRay -> String
number r =
    attributeOrDefault .number r


master_name : CosmicRay -> String
master_name r =
    attributeOrDefault .masterName r


master_name_for : Locale.Locale -> CosmicRay -> String
master_name_for locale r =
    localizedCopyOrDefault locale .masterName r


archangel_name : CosmicRay -> String
archangel_name r =
    attributeOrDefault .archangelName r


archangel_name_for : Locale.Locale -> CosmicRay -> String
archangel_name_for locale r =
    localizedCopyOrDefault locale .archangelName r


color_name : CosmicRay -> String
color_name r =
    attributeOrDefault .colorName r


index : CosmicRay -> Int
index r =
    case r of
        Um ->
            0

        Dois ->
            1

        Tres ->
            2

        Quatro ->
            3

        Cinco ->
            4

        Seis ->
            5

        Sete ->
            6
