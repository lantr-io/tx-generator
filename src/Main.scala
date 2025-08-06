package txgenerator

import com.monovore.decline.{Command, Opts}
import org.scalacheck.Arbitrary
import scalus.cardano.ledger.*
import scalus.cardano.ledger.ArbitraryInstances.given
import scalus.utils.Hex
import scalus.utils.Hex.toHex
import cats.syntax.all.*
import scalus.cardano.address.Address

import java.net.URI
import java.net.http.{HttpClient, HttpRequest, HttpResponse}
import java.time.Duration
import java.util.concurrent.atomic.AtomicLong

case class Config(
    targetUrl: String,
    numTransactions: Long,
    delayMs: Long,
    numThreads: Int
)

object TxGenerator {

    private val outGen = for
        address <- Arbitrary.arbitrary[Address]
        coin <- Arbitrary.arbitrary[Coin]
    yield TransactionOutput(address, Value(coin))

    private def generateTransaction(): Transaction = {
        val in = Arbitrary.arbitrary[TransactionInput].sample.get
        val out = outGen.sample.get
        Transaction(
          body = TransactionBody(
            inputs = Set(in),
            outputs = IndexedSeq(Sized(out)),
            fee = Coin(0L)
          ),
          witnessSet = TransactionWitnessSet.empty
        )
    }

    private def submitTransaction(httpClient: HttpClient, url: String, tx: Transaction): Unit = {
        val cborHex = tx.toCbor.toHex
        val submitUrl = s"$url/submit?tx_cbor=$cborHex"
        val request = HttpRequest
            .newBuilder()
            .uri(URI.create(submitUrl))
            .timeout(Duration.ofSeconds(5))
            .POST(HttpRequest.BodyPublishers.noBody())
            .build()

        try {
            httpClient.send(request, HttpResponse.BodyHandlers.ofString())
        } catch {
            case e: Exception =>
                println(s"Error submitting transaction: ${e.getMessage}")
                Thread.sleep(100) // Wait before retrying
        }
    }

    private def runGenerator(config: Config): Unit = {
        println(s"Starting transaction generator...")
        println(s"Target URL: ${config.targetUrl}")
        println(s"Number of transactions: ${
                if config.numTransactions == Long.MaxValue then "unlimited"
                else config.numTransactions.toString
            }")
        println(s"Delay between transactions: ${config.delayMs}ms")
        println(s"Number of concurrent threads: ${config.numThreads}")

        val httpClient = HttpClient
            .newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build()

        val count = new AtomicLong(0)
        val threads = (1 to config.numThreads).map { _ =>
            Thread.ofVirtual().start(() => {
                while count.get() < config.numTransactions do
                    if count.incrementAndGet() <= config.numTransactions then
                        val tx = generateTransaction()
                        submitTransaction(httpClient, config.targetUrl, tx)
                        val current = count.get()
                        if current % 1000 == 0 then println(s"Submitted $current transactions")
                        if config.delayMs > 0 then Thread.sleep(config.delayMs)
            })
        }

        threads.foreach(_.join())
        println(s"Completed. Total transactions submitted: ${count.get()}")
    }

    private val urlOpt = Opts
        .option[String](
          "url",
          help = "Target URL for transaction submission"
        )
        .withDefault("http://127.0.0.1:3000")

    private val numTxsOpt = Opts
        .option[Long](
          "count",
          help = "Number of transactions to generate (unlimited if not specified)"
        )
        .withDefault(Long.MaxValue)

    private val delayOpt = Opts
        .option[Long](
          "delay",
          help = "Delay in milliseconds between transactions"
        )
        .withDefault(0L)

    private val threadsOpt = Opts
        .option[Int](
          "threads",
          help = "Number of concurrent threads for transaction generation"
        )
        .withDefault(10)

    private val configOpt = (urlOpt, numTxsOpt, delayOpt, threadsOpt).mapN(Config.apply)

    private val command = Command(
      name = "tx-generator",
      header = "Generate and submit Cardano transactions"
    )(configOpt)

    def main(args: Array[String]): Unit = {
        command.parse(args) match
            case Left(help)    => println(help)
            case Right(config) => runGenerator(config)
    }
}
