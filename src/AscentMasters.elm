module AscentMasters exposing
    ( CosmicRay
    , archangel_image
    , archangel_name
    , color_name
    , for_birthday
    , master_details
    , master_image
    , master_name
    , number
    , ray_details
    , test_subject
    )

import Array exposing (Array)
import Date exposing (Date)


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
    Array.fromList
        [ "1-el-morya.png", "2-lanto.png", "3-rowena.png", "4-seraphys-bey.png", "5-hilarion.png", "6-mestra-nada.png", "7-saint-germain.png" ]
        |> getWithDefault r


archangel_image : CosmicRay -> String
archangel_image r =
    Array.fromList [ "1-arcanjo-miguel.png", "2-arcanjo-jofiel.png", "3-arcanjo-samuel.png", "4-arcanjo-gabriel.png", "5-arcanjo-rafael.png", "6-arcanjo-uriel.png", "7-arcanjo-ezequiel.png" ]
        |> getWithDefault r


master_details : CosmicRay -> String
master_details r =
    Array.fromList
        [ "O Mestre El Morya, no tempo do Mestre Jesus, foi Melchior, um dos três sábios dos países do Oriente. Ele foi o lendário Rei Arthur da Sagrada Taça Graal, bem como o humanista e estadista Thomas Morus, que escreveu A Utopia."
        , "O Mestre Lanto em tempos passados, foi um grande governante da China e fez sua ascensão há muitos séculos. Depois conquistou o direito de assumir maiores encargos e foi assim que ele transferiu a custódia de seu Templo de Luz que fica na China, ao sul da Grande Muralha perto de Lanchow, ao seu discípulo Confúcio, que presentemente lá trabalha. No seu grande amor, o Mestre Lanto resolveu ficar por aqui para ajudar a Terra nesta época de crise."
        , "A Mestra Rowena está pronta para servir a todos que a procuram. Ela estimula, mantém e protege, não só os gênios que já conseguiram alcançar o topo da escada, como também, igualmente, os humildes aspirantes que acabam de colocar os pés no primeiro degrau, em direção à meta. Ela guarda o símbolo da Liberdade. O Foco de Luz da Chama da Liberdade guardada pela Mestra Rowena situa-se no sul da França, em Chateau Liberté, no plano físico."
        , "O Mestre Seraphis Bay é invocado para harmonia, pureza e ascensão. Também afasta o Gênio Contrário. Sua proteção está subordinada à atual Chama da Ascensão de Luxor no Egito, que foi levada por ele e outros devotos para lá antes de submergir nas ondas do oceano, o continente de Atlântida."
        , "O Mestre Hilarion no tempo do Mestre Jesus foi o apóstolo Paulo. Seu santuário está no campo etéreo, situado sobre a Ilha de Creta. A chama verde é curadora, deve-se compreender que tanto pode ser a cura do físico, como também a cura da alma da humanidade."
        , "O Mestre Jesus foi seu diretor até pouco tempo atrás, quando juntamente com o Mestre Kuthumi, se elevaram à condição de Instrutores do Mundo. Hoje sua responsável é a Mestra Nada e juntamente com Maria de Nazaré – Mãe de Jesus, elas prestam serviços em benefício da humanidade. Seu templo de iluminação encontra-se na América do Sul. Costuma-se prestar homenagens a esta mestra do Raio Rubi, no início da Primavera, quando a natureza, aparentemente \"morta\", desperta para a vida."
        , "O Mestre Saint Germain, realizou sua ascensão no ano de 1684. É tarefa do Sétimo Raio instruir a humanidade de como conseguir por meio da Chama Violeta a libertação, transmutar seus erros, transformar-se e tudo recomeçar. É um instrumento cósmico e divino, usado pelas Ascencionadas Legiões da Luz, para libertar toda vida prisioneira. Estamos na Era de Aquário e com ela recebemos a proteção da Chama Violeta transmutadora dirigida por nosso amado Mestre Saint Germain. Seu santuário fica no monte Shasta, na Califórnia – EUA. Estamos vivendo a nossa Encarnação de Ouro, o livre arbítrio não nos foi tirado, mas agora a escolha é clara: a luz ou as trevas. Toda essa hierarquia cósmica, estes seres maravilhosos e dentre eles, os Arcanjos e Anjos, se fazem presentes como nunca, unicamente para nos libertar. Isso está acontecendo graças ao grande trabalho dos Mestres Ascencionados e de seus trabalhadores na Terra."
        ]
        |> getWithDefault r


ray_details : CosmicRay -> String
ray_details r =
    Array.fromList
        [ "A chama do Raio Azul Representa: Fé, Poder e Ação. As pessoas deste raio são muitas vezes fáceis de serem reconhecidas em relação às outras, em geral essas pessoas possuem ilimitada força e energia. Elas criam e constroem, possuem ação, são líderes natos."
        , "A chama do Raio Dourado Representa: Sabedoria, Elevação e Iluminação. Deve-se sempre visualizar esta cor envolvendo nosso corpo quando necessitamos dos atributos que ela pode nos dar. É o raio do educador e do professor."
        , "A chama do Raio Rosa Representa: Amor Incondicional, Adoração e Beleza. As pessoas que a ele pertencem amam a beleza em todas as formas de expressão e são amáveis e compassivas."
        , "A chama do Raio Branco Representa: Harmonia, Pureza e Ascensão. As pessoas que pertencem a este raio são, geralmente, dotadas de talento artístico com tendências para música, danças clássicas, teatro de óperas, pintura, escultura e arquitetura. Tais pessoas são quase sempre abençoadas com o poder espiritual e cheias de ânimo, além de possuírem o dom de \"penetrar e ver através das coisas\"."
        , "A chama do Raio Verde Representa: Verdade, Abundância e Cura. As pessoas que pertencem a este raio geralmente atuam nas áreas de pesquisa científica e da saúde, como médicos, enfermeiros e curandeiros."
        , "A chama do Raio Rubi Representa: Devoção, Cooperação e Serviços Prestados à Cura e a Paz da Humanidade. As pessoas deste raio geralmente se dedicam a servir a humanidade muitas vezes sem obter reconhecimentos dos serviços prestados, como sacerdotes, religiosos e missionários."
        , "A chama do Raio Violeta representa: Transmutação, Purificação e Magnetização. As pessoas que pertencem a este raio possuem muitas aptidões e grande amor pela liberdade."
        ]
        |> getWithDefault r


number : CosmicRay -> String
number r =
    Array.fromList [ "1", "2", "3", "4", "5", "6", "7" ]
        |> getWithDefault r


master_name : CosmicRay -> String
master_name r =
    Array.fromList [ "Mestre El Morya", "Mestre Lanto", "Mestra Rowena", "Mestre Seraphys Bey", "Mestre Hilarion", "Mestra Nada", "Mestre Saint German" ]
        |> getWithDefault r


archangel_name : CosmicRay -> String
archangel_name r =
    Array.fromList [ "Miguel", "Jofiel", "Samuel", "Gabriel", "Rafael", "Uriel", "Ezequiel" ]
        |> getWithDefault r


color_name : CosmicRay -> String
color_name r =
    Array.fromList [ "blue", "gold", "pink", "whitesmoke", "green", "maroon", "blueviolet" ]
        |> getWithDefault r


getWithDefault : CosmicRay -> Array String -> String
getWithDefault r arr =
    (Array.get (index r) >> Maybe.withDefault "") arr


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
